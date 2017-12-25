from django.shortcuts import render
from django.http import HttpResponse,JsonResponse
from django.shortcuts import render
from kscore.session import get_session
from django.conf import settings
ACCESS_KEY_ID = settings.ACCESS_KEY_ID
SECRET_ACCESS_KEY = settings.SECRET_ACCESS_KEY
# Create your views here.
def subnet_index(request):
    s = get_session()
    client_vpc = s.create_client("vpc", 'cn-beijing-6', use_ssl=False, ks_access_key_id=ACCESS_KEY_ID,
                                 ks_secret_access_key=SECRET_ACCESS_KEY)
    subnets = {"SubnetSet": []}
    for i in client_vpc.describe_subnets()['SubnetSet']:
        print(i)

    return render(request, 'subnet/index.html')