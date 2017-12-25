from django.test import TestCase
import re
# Create your tests here.
# subnetname_list = ['v4_subnet', 'v3_subnet', 'v2_subnet', 'v1_subnet', 'v0_subnet']
# # print(a.split('_')[0].split('v')[1])
# for s_num in subnetname_list:
#     print(s_num.split('_')[0].split('v')[1])
#     print(max(re.findall(r'\d+', s_num)))

a = '172.66.0.0/16'
b = 'v4_subnet_d132'
ip_sect = ".".join(a.split(".")[0:2]) + "."
ret = re.findall('\d+', b)
c = re.findall(r'\d+', re.split('_', b, 1)[0])
print('.'.join(ret[0:2]))
print('c:', c)