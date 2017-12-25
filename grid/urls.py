"""cms URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/1.9/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  url(r'^$', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  url(r'^$', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.conf.urls import url, include
    2. Add a URL to urlpatterns:  url(r'^blog/', include('blog.urls'))
"""
# coding=utf-8
from django.conf.urls import url, include
import grid.views as grid_views

urlpatterns = [
    url(r'^newgrid/', grid_views.newgrid, name='newgrid'),
    url(r'^test/', grid_views.test, name='test'),
    url(r'^task/(?P<task_id>[\w-]+)', grid_views.task, name='task'),
    url(r'^retry/$', grid_views.retry_init, name='retry_init'),
    url(r'^vpcs/(?P<region>[\w-]+)', grid_views.vpcs, name='vpcs'),
    url(r'^subnets/(?P<region>[\w-]+)/(?P<vpc_id>[\w-]+)', grid_views.subnets, name='subnets'),
    url(r'^create_subnets/(?P<data>[\w-]+)/(?P<region>[\w-]+)/(?P<vpc>[\w-]+)', grid_views.create_subnets, name='create_subnets'),

    url(r'^grid_update/', grid_views.grid_update, name='grid_update'),
    url(r'^gitlab_project/', grid_views.gitlab_project, name='gitlab_project'),
    url(r'^gitlab_tag/(?P<project_id>[\w-]+)', grid_views.gitlab_tag, name='gitlab_tag'),
    url(r'^down_files/(?P<project_id>[\w-]+)/(?P<tag_name>[\w-]+[\w\d\.]+)', grid_views.down_files, name='down_files'),

]
