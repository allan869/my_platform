from django.shortcuts import render
from django.http import JsonResponse, HttpResponse


from kscore.session import get_session
from django.conf import settings
import traceback
import logging
import time
import json
from grid.forms import CreateECS
from grid.logic import init_ecs, delay_test, test_ecs, create_ecs
from celery.result import AsyncResult
import re
import gitlab
import os
ACCESS_KEY_ID = settings.ACCESS_KEY_ID
SECRET_ACCESS_KEY = settings.SECRET_ACCESS_KEY


log = logging.getLogger('django')


def mytask():
    print("start task")
    time.sleep(10)
    print("finish task")

def newgrid(request):
    """
    进入新建Grid主机页面
    post请求创建服务器
    :param request: 
    :return: 
    """
    if request.method == 'GET':
        return render(request, 'grid/index.html', context=locals())
    else:
        try:
            form_data = json.loads(request.body.decode("utf-8"))
            if 'vpc' in form_data and 'subnet' in form_data and 'region' in form_data \
                and 'hostnames_I14B' in form_data and 'hostnames_I14C' in form_data \
                and (form_data['hostnames_I18B'] or form_data['hostnames_I18A']
                     or form_data['hostnames_I14B'] or form_data['hostnames_I14C']):
            # form = CreateECS(form_data)
            # if form.is_valid():
            #     data = form.cleaned_data
                data = form_data
                log.info("creating...", data)

                task = create_ecs.delay(data)
                return JsonResponse({"result": True, "message": "Creating ECS....", "task_id": task.id})

            else:
                log.error("表单异常! ")
                return JsonResponse({"result": False, "message": "Form error, Please check your Input."})
        except Exception as e:
            traceback.print_exc()


def retry_init(request):
    """
    重试初始化进程
    :param request: body: [{'InstanceName': 'bj-ksy-vn-java-01', 'InstanceId': '218edaab-3f0f-4c5f-8775-54c961779e99'},] 
    :return: 
    """
    try:
        data = json.loads(request.body.decode("UTF-8"))
        _task = init_ecs.delay(data)
        return JsonResponse({"result": True, "message": "初始化中", "task_id": _task.id})
    except Exception as e:
        log.error(traceback.format_exc())
        return JsonResponse({"result": False, "message": "执行失败：" + traceback.format_exc()})


def task(request, task_id):
    _task = AsyncResult(task_id)
    if _task:
        print({"result": True, "message": _task.result, "status": _task.status})
        return JsonResponse({"result": True, "message": _task.result, "status": _task.status})
    else:
        return JsonResponse({"result": False, "message": "Task Not found"})



def test(request):
    data = [{'InstanceId': '622a2477-4f13-4497-be9c-80e50f03e27b', 'InstanceName': 'bj-ksy-vtest-java-01'}, {'InstanceId': 'ff53cfa8-ff6f-4f6a-800a-2a722c1ec7c9', 'InstanceName': 'bj-ksy-vtest-t2d-01'}, {'InstanceId': 'f748e3ba-457b-4a3d-99ae-0a441f7b918b', 'InstanceName': 'bj-ksy-vtest-tchat-01'}]

    r = init_ecs.delay(data, {'region': 'cn-beijing-6'})
    print(r)
    return HttpResponse("Init Server...")

def vpcs(request, region):
    """
    查询指定区域的所有vpc
    :param request: 
    :param region: 
    :return: 
    """
    s = get_session()
    client_vpc = s.create_client("vpc", region, use_ssl=False, ks_access_key_id=ACCESS_KEY_ID,
                                 ks_secret_access_key=SECRET_ACCESS_KEY)
    return JsonResponse(client_vpc.describe_vpcs())


def subnets(request, region, vpc_id):
    """
    查询指定区域、指定vpc的所有子网
    :param request: 
    :param region: 
    :param vpc_id: 
    :return: 
    """
    try:
        s = get_session()
        client_vpc = s.create_client("vpc", region, use_ssl=False, ks_access_key_id=ACCESS_KEY_ID,
                                     ks_secret_access_key=SECRET_ACCESS_KEY)
        subnets = {"SubnetSet": []}
        for i in client_vpc.describe_subnets()['SubnetSet']:
            if i['VpcId'] == vpc_id:
                subnets['SubnetSet'].append(i)

        return JsonResponse(subnets)
    except Exception as e:
        traceback.print_exc()

def create_subnets(request, data, region, vpc):
    """
    创建子网
    :param request: 
    :param data: 前端按钮v,p
    :param region: 金山云区域
    :param vpc: vpc_id
    :return: 
    """
    s = get_session()
    client_vpc = s.create_client("vpc", region, use_ssl=False, ks_access_key_id=ACCESS_KEY_ID,
                                 ks_secret_access_key=SECRET_ACCESS_KEY)
    cidrblock_re = ''
    cidrblock = []
    subnetname_list = []
    subnet_list = []
    subnet_num = []
    subnetname_new = []
    subnet_new = ''
    # print(data, region, vpc)

    # for v in client_vpc.describe_subnets(**{"Dns2.1": ['InstanceId']})['SubnetSet']:
    #     print('v---------->:', v)

    # 根据VPCID切子网段，用于拼接新的子网
    for k in client_vpc.describe_vpcs()['VpcSet']:
        if k['VpcId'] == vpc:
            # print(k)
            cidrblock.append(k['CidrBlock'])
            cidrblock_re = ".".join(k['CidrBlock'].split(".")[0:2]) + "."
    # print('cidrblock_re:', type(cidrblock_re), cidrblock_re, cidrblock)

    # 根据VPCID取出的子网的名称和所有已有子网
    for i in client_vpc.describe_subnets()['SubnetSet']:
        if i['VpcId'] == vpc:
            # print('****', i)
            # subnets[i['SubnetName']] = i['CidrBlock']
            subnetname_list.append(i['SubnetName'])
            subnet_list.append(i['CidrBlock'])
    # print(subnetname_list, subnet_list)

    # 根据创建时根据当前最大名称排序+1(v)或者-1(p)的原则组成新的子网名称,
    for s_num in subnetname_list:
        if s_num.startswith(data):
            # print(s_num, re.findall(r'\d+', s_num))
            # print(s_num, s_num.split('_')[0].split(data)[1])
            for x in re.findall(r'\d+', re.split('_', s_num, 1)[0]):
                subnet_num.append(int(x))
                # print(type(subnet_num[0]), subnet_num)
    # print('max_num:', subnet_num)

    # 创建子网
    count = 0
    while count < 5:
        count += 1
        # print('count:', count)
        subnetname_new = data + str(max(subnet_num) + count) + '_' + 'subnet'
        # print(subnetname_new)
        if data == 'v':
            subnet_new = cidrblock_re + str(max(subnet_num)+count) + '.0/24'
            # print(subnet_new)
            if subnet_new in subnet_list:
                # print('aaa', subnet_new)
                continue
            else:
                # print('bbb', subnet_new)
                client_vpc.create_subnet(AvailabilityZoneName=region, SubnetName=subnetname_new, CidrBlock=subnet_new,
                                         SubnetType='Normal',
                                         DhcpIpFrom=cidrblock_re + str(max(subnet_num)+count) + '.2',
                                         DhcpIpTo=cidrblock_re + str(max(subnet_num)+count) + '.253',
                                         GatewayIp=cidrblock_re + str(max(subnet_num)+count) + '.1', Dns1='198.18.254.30',
                                         Dns2='198.18.254.31', VpcId=vpc)
                # print(cidrblock_re + str(max(subnet_num)+count) + '.2')
                break

        if data == 'p':
            subnet_new = cidrblock_re + str(254 - (max(subnet_num)+count)) + '.0/24'
            # print(subnet_new)
            if subnet_new in subnet_list:
                # print('aaa', subnet_new)
                continue
            else:
                # print('aaa', subnet_new)
                client_vpc.create_subnet(AvailabilityZoneName=region, SubnetName=subnetname_new, CidrBlock=subnet_new,
                                         SubnetType='Normal',
                                         DhcpIpFrom=cidrblock_re + str(254 - (max(subnet_num) + count)) + '.2',
                                         DhcpIpTo=cidrblock_re + str(254 - (max(subnet_num) + count)) + '.253',
                                         GatewayIp=cidrblock_re + str(254 - (max(subnet_num) + count)) + '.1', Dns1='198.18.254.30',
                                         Dns2='198.18.254.31', VpcId=vpc)
                # print(cidrblock_re + str(254 - (max(subnet_num) + count)) + '.2')
                break
    # return HttpResponse('dididi')
    return JsonResponse({'data': subnet_new})

def grid_update(request):
    return render(request, 'grid/grid_update.html', locals())

def gitlab_project(request):
    """
    此功能获取所有的项目
    :param request: 
    :return: 
    """
    # ret = {
    #     'name_with_namespace': 'devops / swarm-compose',
    #     'permissions': {'group_access': {'access_level': 40, 'notification_level': 3},'project_access': None},
    #     'last_activity_at': '2017-08-29T13:57:53.760+08:00',
    #     'web_url': 'http://git.cctv.cn/devops/swarm-compose',
    #     'container_registry_enabled': True,
    #     'ssh_url_to_repo': 'git@git.cctv.cn:devops/swarm-compose.git',
    #     'issues_enabled': True,
    #     'default_branch': 'master',
    #     'request_access_enabled': False,
    #     'only_allow_merge_if_all_discussions_are_resolved': False,
    #     'shared_with_groups': [], 'merge_requests_enabled': True,
    #     'forks_count': 0,
    #     # '_module': "<module 'gitlab.v3.objects' from '/Users/zhangkai/.virtualenvs/CMDB/lib/python3.5/site-packages/gitlab/v3/objects.py'>",
    #     'id': 410,
    #     # 'namespace': "<Group id:133>",
    #     'tag_list': [],
    #     'wiki_enabled': True,
    #     'name': 'swarm-compose',
    #     'path_with_namespace': 'devops/swarm-compose',
    #     'gitlab': "<gitlab.Gitlab object at 0x1054c7ac8>",
    #     'shared_runners_enabled': True,
    #     'lfs_enabled': True,
    #     'path': 'swarm-compose',
    #     'open_issues_count': 0,
    #     'visibility_level': 10,
    #     'public': False,
    #     'only_allow_merge_if_build_succeeds': False,
    #     'creator_id': 104,
    #     'builds_enabled': True,
    #     'http_url_to_repo': 'http://git.cctv.cn/devops/swarm-compose.git',
    #     '_from_api': True,
    #     'snippets_enabled': True,
    #     'star_count': 0,
    #     'description': '',
    #     'avatar_url': None,
    #     'archived': False,
    #     'created_at': '2017-08-29T11:36:51.252+08:00',
    #     'public_builds': True
    # }

    project_data = {'data': []}
    gl = gitlab.Gitlab('http://git.cctv.cn/', 'sT2Gq84pSZPpMr9MNL89')
    gl.auth()
    projects = gl.projects.list(all=True)
    for project in projects:
        # print(project)
        project_data['data'].append(dict(id=project.id, name=project.name))
    # print('project_data:::::::::', project_data)
    # return JsonResponse({'data': [{'value': '选项1', 'label': 'fuck'}, {'value': '选项2', 'label': 'fuckk'}, {'value': '选项3', 'label': 'fuckkk'}]})

    return JsonResponse(project_data)

def gitlab_tag(request, project_id):
    # print(project_id)
    tag_data = {'data': []}
    gl = gitlab.Gitlab('http://git.cctv.cn/', 'sT2Gq84pSZPpMr9MNL89')
    gl.auth()
    tags = gl.project_tags.list(project_id=project_id)
    for tag in tags:
        # print(tag.name, tag)
        tag_data['data'].append(dict(id=tag.project_id, name=tag.name))
    # print('tag_data::::::::', tag_data)

    return JsonResponse(tag_data)

def down_files(request, project_id, tag_name):
    print(project_id, tag_name)
    gl = gitlab.Gitlab('http://git.cctv.cn/', 'sT2Gq84pSZPpMr9MNL89')
    gl.auth()
    try:
        f = gl.project_files.get(file_path='docker-compose.yml', ref=tag_name, project_id=project_id)
        dir_path = 'upload' + '/' + 'docker_files' + '/' + tag_name
        file_path = 'upload' + '/' + 'docker_files' + '/' + tag_name + '/' + 'docker-compose.xml'
        if os.path.exists(dir_path) == False:
            os.makedirs(dir_path)
        ret = f.decode().decode('utf-8')
        # print(ret)
        with open(file_path, 'w+') as docker_file:
            docker_file.write(ret)
            docker_file.close()
    except Exception as e:
        traceback.print_exc()
    return JsonResponse({'data': 'docker-compose.xml'})