import my_logging as mylog
import remind_wechat as wechat
from ftplib import FTP


logger = mylog.MyLogger(name='ftp_upload')
openID="oIAZG6FN5E74DJ6kvxO8J2fe04Oo"
wechat.sendMsg(openID, "FTP upload started.")

# set remote directory and local file name
date_format = '20240601' # YYYYMMDD
dirname = date_format

local_finame = "Z_NAFP_C_USTC" + "_" + date_format + "120000" + "_P_YBJS-DAY-" + date_format + ".TXT"

# ftp configuration parameters
ip_addr = '106.120.82.188'
username = 'ftp4incoming0202'
passward = 'Aecohr9m2024'

#ftp login and upload
ftp = FTP(ip_addr)
ftp.login(user=username, passwd=passward)
ftp.cwd(dirname)
with open(local_finame, 'rb') as local_file:
    ftp.storbinary(f'STOR {local_finame}',local_file)
list = ftp.nlst()
wechat.sendMsg(openID, list)
ftp.quit()
