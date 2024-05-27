import os
import my_logging as mylog

logger = mylog.MyLogger("scp_transfer")
local_path = "/home/jungu/Projects/model_run"
remote_host = "Micro" #Please add this to your ~/.ssh/config file
remote_path = "/home/lacar_group/jungu/2024ClimPre"

try:
    os.system("scp -r " + local_path + " " + remote_host + ":" + remote_path)
    logger.info("scp transfer completed successfully")
except Exception as e:
    logger.error("scp transfer failed: " + str(e))

