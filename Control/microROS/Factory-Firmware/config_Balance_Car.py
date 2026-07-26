import serial
import struct
import time

'''
Author  : Yahboom Team
Version : V1.1.5
LastEdit: 2024.11.12
'''


"""
ORDER 用来存放命令地址和对应数据
ORDER is used to store the command address and corresponding data
"""
ORDER = {
    
    "WIFI_SSID": [0x01],
    "WIFI_PASSWD": [0x02],
    "AGENT_IP": [0x03, 0, 0, 0, 0],
    "AGENT_PORT": [0x04, 0, 0],
    "CAR_TYPE": [0x05, 0, 0],
    "DOMAIN_ID": [0x06, 0, 0],
    "SERIAL_BAUDRATE": [0x07, 0, 0, 0, 0],
    "SERVO_OFFSET": [0x08, 0, 0],
    "MOTOR_PID": [0x09, 0, 0, 0, 0, 0, 0],
    "IMU_YAW_PID": [0x0A, 0, 0, 0, 0, 0, 0],
    "ROS_NAMESPACE": [0x0B],

    "REBOOT_DEVICE": [0x20, 0x00, 0X00],
    "RESET_CONFIG": [0x21, 0x00, 0X00],

    "REQUEST_DATA": [0x50, 0, 0],
    "FIRMWARE_VERSION": [0x51],
}


class MicroROS_Robot():

    def __init__(self, port="COM10", debug=False):
        self.__ser = serial.Serial(port, 115200, timeout=0.05)
        self.__rx_FLAG = 0
        self.__rx_COUNT = 0
        self.__rx_ADDR = 0
        self.__rx_LEN = 0
        self.__RX_BUF_LEN_MAX = 40
        self.__rx_DATA = bytearray(self.__RX_BUF_LEN_MAX)
        self.__send_delay = 0.01
        self.__read_delay = 0.01
        self.__debug = debug

        self.__HEAD = 0xFF
        self.__DEVICE_ID = 0xF8
        self.__RETURN_ID = 0xF7
        self.__READ_DATA = 0x50

        self.AGENT_TYPE_WIFI_UDP = 0
        self.AGENT_TYPE_SERIAL = 1

        self.CAR_TYPE_COMPUTER = 0
        self.CAR_TYPE_UASRT_CAR = 1 #串口代理，用于调试

    # 发送一些数据到设备 
    # Send some data to device
    def __send(self, key, len=1):
        order = ORDER[key][0]
        value = []
        value_sum = 0
        for i in range(0, len):
            value.append(ORDER[key][1 + i])
            value_sum = value_sum + ORDER[key][1 + i]
        sum_data = (self.__HEAD + self.__DEVICE_ID + (len + 0x05) + order + value_sum) % 256
        tx = [self.__HEAD, self.__DEVICE_ID, (len + 0x05), order]
        tx.extend(value)
        tx.append(sum_data)
        self.__ser.write(tx)
        if self.__send_delay > 0:
            time.sleep(self.__send_delay)
        if self.__debug:
            print ("Send: [0x" + ', 0x'.join('{:02X}'.format(x) for x in tx) + "]")
            # print ("Send: [" + ' '.join('{:02X}'.format(x) for x in tx) + "]")

    # 发送请求数据 
    # Send request data
    def __request(self, addr, param=0):
        order = self.__READ_DATA
        buf_len = 7
        sum_data = (self.__HEAD + self.__DEVICE_ID + buf_len + order + addr + param) % 256
        tx = [self.__HEAD, self.__DEVICE_ID, buf_len, order, addr, param, sum_data]
        self.__ser.flushInput()
        self.__ser.flushOutput()
        for i in range(self.__RX_BUF_LEN_MAX):
            self.__rx_DATA[i] = 0
        self.__ser.write(tx)
        if self.__debug:
            print ("Read: [0x" + ', 0x'.join('{:02X}'.format(x) for x in tx) + "]")
            # print ("Read: [" + ' '.join('{:02X}'.format(x) for x in tx) + "]")

    # 解析数据 parse data
    def __unpack(self):
        n = self.__ser.inWaiting()
        rx_CHECK = 0
        if n:
            #print("OK")
            data_array = self.__ser.read_all()
            if self.__debug:
                # print("rx_data:", list(data_array))
                print ("rx_data: [0x" + ', 0x'.join('{:02X}'.format(x) for x in data_array) + "]")
                # print ("rx_data: [" + ' '.join('{:02X}'.format(x) for x in data_array) + "]")
            for data in data_array:
                if self.__rx_FLAG == 0:
                    if data == self.__HEAD:
                        self.__rx_FLAG = 1
                    else:
                        self.__rx_FLAG = 0

                elif self.__rx_FLAG == 1:
                    if data == self.__RETURN_ID:
                        self.__rx_FLAG = 2
                    else:
                        self.__rx_FLAG = 0

                elif self.__rx_FLAG == 2:
                    self.__rx_LEN = data
                    self.__rx_FLAG = 3

                elif self.__rx_FLAG == 3:
                    self.__rx_ADDR = data
                    self.__rx_FLAG = 4
                    self.__rx_COUNT = 0

                elif self.__rx_FLAG == 4:
                    if self.__rx_COUNT < self.__rx_LEN - 5:
                        self.__rx_DATA[self.__rx_COUNT] = data
                        self.__rx_COUNT = self.__rx_COUNT + 1
                    if self.__rx_COUNT >= (self.__rx_LEN - 5):
                        self.__rx_FLAG = 5

                elif self.__rx_FLAG == 5:
                    for i in self.__rx_DATA:
                        rx_CHECK = rx_CHECK + i
                    rx_CHECK = (self.__HEAD + self.__RETURN_ID + self.__rx_LEN + self.__rx_ADDR + rx_CHECK) % 256
                    if data == rx_CHECK:
                        self.__rx_FLAG = 0
                        self.__rx_COUNT = 0
                        return True
                    else:
                        self.__rx_FLAG = 0
                        self.__rx_COUNT = 0
                        self.__rx_ADDR = 0
                        self.__rx_LEN = 0
        return False


    # 重启设备 
    # reboot device
    def reboot_device(self):
        # ORDER["REBOOT_DEVICE"][1] = 0x5F
        # ORDER["REBOOT_DEVICE"][2] = 0x5F
        # self.__send("REBOOT_DEVICE", len=2)
        self.__ser.setDTR(False)
        self.__ser.setRTS(True)
        time.sleep(.1)
        self.__ser.setDTR(True)
        self.__ser.setRTS(True)
        time.sleep(2)
    
    # 恢复出厂配置, 重启生效
    # Restore factory Settings, Restart to take effect
    def reset_factory_config(self):
        ORDER["RESET_CONFIG"][1] = 0x5F
        ORDER["RESET_CONFIG"][2] = 0x5F
        self.__send("RESET_CONFIG", len=2)

    # 配置WiFi信息，输入WiFi信号名称及密码。重启生效
    # Configure the WiFi information, enter the WiFi signal name and password. Restart takes effect.
    def set_wifi_config(self, ssid, passwd):
        """
        配置WiFi信息, 输入WiFi信号名称和密码。重启生效
        输入参数示例: ssid="ssid123", passwd="passwd123"

        Configure WiFi information, enter WiFi signal name and password. Restart to take effect
        Input parameter example: ssid="ssid123", passwd="passwd123"
        """
        ssid_bytes = bytes(str(ssid), "utf-8")
        for i in range(len(ssid)):
            ORDER["WIFI_SSID"].append(ssid_bytes[i])
        self.__send("WIFI_SSID", len=len(ssid))
        passwd_bytes = bytes(str(passwd), "utf-8")
        for i in range(len(passwd)):
            ORDER["WIFI_PASSWD"].append(passwd_bytes[i])
        self.__send("WIFI_PASSWD", len=len(passwd))

    # Configure the WiFi proxy IP address and port number. Restart to take effect
    def set_udp_config(self, ip, port):
        '''
        配置WiFi代理IP地址和端口号。重启生效
        输入参数示例: ip=[192,168,2,116],port=8899

        Configure WiFi proxy IP address and port number. Restart to take effect
        Input parameter example: ip=[192,168,2,116],port=8899
        '''
        ORDER["AGENT_IP"][1] = int(ip[0]) & 0xFF
        ORDER["AGENT_IP"][2] = int(ip[1]) & 0xFF
        ORDER["AGENT_IP"][3] = int(ip[2]) & 0xFF
        ORDER["AGENT_IP"][4] = int(ip[3]) & 0xFF
        self.__send("AGENT_IP", len=4)
        ORDER["AGENT_PORT"][1] = int(port)&0xFF
        ORDER["AGENT_PORT"][2] = int(port>>8)&0xFF
        self.__send("AGENT_PORT", len=2)

    # Configure the baud rate for ROS serial communication. Restart to take effect
    def set_ros_serial_baudrate(self, baudrate):
        '''
        配置ROS串口通讯波特率。重启生效
        输入参数示例: baudrate=115200

        Configure the ROS serial communication baud rate. Restart to take effect
        Input parameter example: baudrate=115200
        '''
        value_s = bytearray(struct.pack('i', int(baudrate)))
        ORDER["SERIAL_BAUDRATE"][1] = value_s[0]
        ORDER["SERIAL_BAUDRATE"][2] = value_s[1]
        ORDER["SERIAL_BAUDRATE"][3] = value_s[2]
        ORDER["SERIAL_BAUDRATE"][4] = value_s[3]
        self.__send("SERIAL_BAUDRATE", len=4)
    
    # Configure the ROS namespace. Restart to take effect
    def set_ros_namespace(self, ros_namespace):
        """
        配置ROS命名空间。重启生效
        输入参数示例: ros_namespace="robot1"

        Configure ROS namespace. Restart to take effect
        Input parameter example: ros_namespace="robot1"
        """
        name_len = len(ros_namespace)
        if name_len > 0:
            name_bytes = bytes(str(ros_namespace), "utf-8")
            for i in range(len(ros_namespace)):
                ORDER["ROS_NAMESPACE"].append(name_bytes[i])
        else:
            name_len = 1
            ORDER["ROS_NAMESPACE"].append(0)
        self.__send("ROS_NAMESPACE", len=name_len)

    # Configure the car type (agent). Restart to take effect
    def set_car_type(self, car_type):
        '''
        配置小车类型（代理方式）。重启生效
        输入参数示例:car_type=0表示虚拟机/电脑版本小车(WiFi代理方式), car_type=1表示树莓派版本小车(串口代理方式)。

        Configure the car type (proxy mode). Restart to take effect
        Input parameter example: car_type=0 means the virtual machine/computer version of the car (WiFi proxy mode), car_type=1 means the Raspberry Pi version of the car (serial port proxy mode).
        '''
        ORDER["CAR_TYPE"][1] = int(car_type) & 0xFF
        ORDER["CAR_TYPE"][2] = 0
        self.__send("CAR_TYPE", len=2)

    # Configure the ROS DOMAIN ID. Restart takes effect.
    def set_ros_domain_id(self, domain_id):
        '''
        配置ROS DOMAIN ID。重启生效。
        输入参数示例:domain_id=30。domain_id取值范围: 0 <= domain_id <= 100

        Configure ROS DOMAIN ID. Restart to take effect.
        Input parameter example: domain_id=30. domain_id value range: 0 <= domain_id <= 100
        '''
        if domain_id > 100:
            domain_id = 100
        if domain_id < 0:
            domain_id = 0
        value_s = bytearray(struct.pack('h', int(domain_id)))
        ORDER["DOMAIN_ID"][1] = value_s[0]
        ORDER["DOMAIN_ID"][2] = value_s[1]
        self.__send("DOMAIN_ID", len=2)


    def read_wifi_ssid(self):
        '''
        读取底板连接的WiFi信号名称

        Read the WiFi signal name connected to the baseboard
        '''
        self.__request(ORDER["WIFI_SSID"][0])
        time.sleep(self.__read_delay)
        str_data = None
        if self.__unpack():
            str_data = self.__rx_DATA.decode('utf-8')
        return str_data

    def read_wifi_passwd(self):
        '''
        读取底板连接的WiFi密码

        Read the WiFi password connected to the baseboard
        '''
        self.__request(ORDER["WIFI_PASSWD"][0])
        time.sleep(self.__read_delay)
        str_data = None
        if self.__unpack():
            str_data = self.__rx_DATA.decode('utf-8')
        return str_data

    def read_agent_ip_addr(self):
        '''
        读取底板WiFi代理的IP地址

        Read the IP address of the baseboard WiFi agent
        '''
        self.__request(ORDER["AGENT_IP"][0])
        time.sleep(self.__read_delay)
        str_data = None
        if self.__unpack():
            str_data = "%d.%d.%d.%d" % (self.__rx_DATA[0], self.__rx_DATA[1], self.__rx_DATA[2], self.__rx_DATA[3])
        return str_data

    def read_agent_ip_port(self):
        '''
        读取底板WiFi代理的IP端口

        Read the IP port of the baseboard WiFi agent
        '''
        self.__request(ORDER["AGENT_PORT"][0])
        time.sleep(self.__read_delay)
        str_data = None
        if self.__unpack():
            port = struct.unpack('h', bytearray(self.__rx_DATA[0:2]))[0]
            str_data = "%d" % (port)
        return str_data

    def read_car_type(self):
        '''
        读取底板小车类型、代理连接方式。

        Read the bottom plate trolley type and proxy connection method.
        '''
        self.__request(ORDER["CAR_TYPE"][0])
        time.sleep(self.__read_delay)
        str_data = None
        if self.__unpack():
            agent = struct.unpack('h', bytearray(self.__rx_DATA[0:2]))[0]
            if agent == self.CAR_TYPE_COMPUTER:
                str_data = "CAR_TYPE_COMPUTER"
            elif agent == self.CAR_TYPE_UASRT_CAR:
                str_data = "CAR_TYPE_UASRT_CAR"
            else:
                str_data = "unknow"
        return str_data

    def read_ros_domain_id(self):
        '''
        读取底板ROS DOMAIN ID

        Read the ROS DOMAIN ID of the baseboard
        '''
        self.__request(ORDER["DOMAIN_ID"][0])
        time.sleep(self.__read_delay)
        str_data = None
        if self.__unpack():
            domain_id = struct.unpack('h', bytearray(self.__rx_DATA[0:2]))[0]
            str_data = "%d" % (domain_id)
        return str_data


    def read_ros_serial_baudrate(self):
        '''
        读取底板ROS串口通讯波特率

        Read the baud rate of the ROS serial port communication on the baseboard
        '''
        self.__request(ORDER["SERIAL_BAUDRATE"][0])
        time.sleep(self.__read_delay)
        str_data = None
        if self.__unpack():
            baudrate = struct.unpack('i', bytearray(self.__rx_DATA[0:4]))[0]
            str_data = "%d" % (baudrate)
        return str_data
    
    def read_ros_namespace(self):
        '''
        读取底板的ROS命名空间

        Read the ROS namespace of the baseboard
        '''
        self.__request(ORDER["ROS_NAMESPACE"][0])
        time.sleep(self.__read_delay)
        str_data = None
        if self.__unpack():
            str_data = self.__rx_DATA.decode('utf-8')
        return str_data

   
    def read_version(self):
        '''
        返回固件版本
        Return the firmware version
        '''
        self.__request(ORDER["FIRMWARE_VERSION"][0])
        time.sleep(self.__read_delay)
        str_version = None
        if self.__unpack():
            str_version = "%d.%d.%d" % (self.__rx_DATA[0], self.__rx_DATA[1], self.__rx_DATA[2])
        return str_version

    # 读取并打印所有配置信息。
    # Read and print all configuration information.
    def print_all_firmware_parm(self):
        version = self.read_version()
        print("version:", version)

        ssid = self.read_wifi_ssid()
        print("ssid:", ssid)
        passwd = self.read_wifi_passwd()
        print("passwd:", passwd)

        ip_addr = self.read_agent_ip_addr()
        print("ip_addr:", ip_addr)
        ip_port = self.read_agent_ip_port()
        print("ip_port:", ip_port)

        car_type = self.read_car_type()
        print("car_type:", car_type)

        domain_id = self.read_ros_domain_id()
        print("domain_id:", domain_id)

        baudrate = self.read_ros_serial_baudrate()
        print("ros_serial_baudrate:", baudrate)

        ros_namespace = self.read_ros_namespace()
        print("ros_namespace:", ros_namespace)




if __name__ == '__main__':
    robot = MicroROS_Robot(port='COM10', debug=False)
    print("Rebooting Device, Please wait.")
    robot.reboot_device()

    robot.set_wifi_config("lab_control", "lab_control")
    robot.set_udp_config([192, 168, 1, 100], 1883)
    robot.set_car_type(robot.CAR_TYPE_COMPUTER)
    #robot.set_car_type(robot.CAR_TYPE_UASRT_CAR)

    robot.set_ros_domain_id(20)
    robot.set_ros_serial_baudrate(115200)
    robot.set_ros_namespace("")
   
   
    time.sleep(.1)
    robot.print_all_firmware_parm()
    print("Please reboot the device to take effect, if you change some device config.")

    try:
        while False:
            # robot.beep(100)
            time.sleep(1)
    except:
        pass
    time.sleep(.1)
    del robot
