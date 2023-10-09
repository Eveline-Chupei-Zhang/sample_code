# -*- coding: utf-8 -*-
"""
Web-scrapping: Google News

@author: Eveline Chupei Zhang
"""

import numpy as np
import pandas as pd
import requests
from bs4 import BeautifulSoup
import re
import random
import time
# !pip install fake_useragent
from fake_useragent import UserAgent

'''
from google.colab import drive
drive.mount("/content/drive")
path = 'drive/My Drive/Colab Notebooks/Cola'
'''

ua = UserAgent()
user_agent = ua.random

#response = requests.get("http://tiqu.linksocket.com:81/abroad?num=500&type=1&lb=1&sb=0&flow=1&regions=&port=1&n=0", timeout=30)

class GoogleCrawler():
    """
    爬取谷歌新闻的搜索结果
    """
    def __init__(self):
        self.ip_list = self.read_ip_list()
        #self.domain_list = self.read_domain_list()
        self.ua_list = self.read_ua_list()
        self.abnormal_list = [] # 保存异常数据

    def get_allpages_result(self, query, start=2010, end=2019, num=10):
        """
        返回关键词query从start年到end年的所有搜索结果
        :param query: 关键词
        :param start: 起始年份
        :param end: 终止年份
        :param num: 每页结果数量
        """
        result_list = [] # 保存每一页的result

        page = 1
        result = self.get_onepage_result(query, start, end, num, page)
        result_list.append(result)

        while len(result) == num: # 只要当前页的结果数量等于每页最大结果数量，就说明没有到最后一页
            page += 1
            result = self.get_onepage_result(query, start, end, num, page)
            result_list.append(result)

        results = pd.concat(result_list, ignore_index=True)

        return results

    def get_onepage_result(self, query, start=2010, end=2019, num=10, page=1):
        """
        返回关键词query从start年到end年的第page页的搜索结果
        :param query: 关键词
        :param start: 起始年份
        :param end: 终止年份
        :param num: 每页结果数量
        """
        result_list = [] # 保存每一条结果

        temp = []

        flag = 1
        while flag < 20:
            try:
                soup = self.get_soup(query, start, end, num, page)
                temp = soup.find_all("a", attrs={"style":"text-decoration:none;display:block"})
                if len(temp) == 0:
                    flag += 1
                else:
                    break
            except:
                flag += 1

        print("------------------------")
        print(f"尝试了{flag}次")

        if len(temp) == 0:
            print("没爬出来数据的：")
            self.abnormal_list.append({"query": query, "page": page})
        else: 
            print("正常爬取的：")

        # 测试
        print(f"关键词为{query}，页码为{page}")
        print(f"url为{self.url}")
        print(f"headers为{self.headers}")
        #print(f"proxies为{self.proxies}")
        print(f"当前页的结果数量为{len(temp)}")
        print("-------------------------")

        soup = self.get_soup(query, start, end, num, page)
        for a in soup.find_all("a", attrs={"style":"text-decoration:none;display:block"}):
            Url = a["href"]
            Title = a.select("div[role='heading']")[0].get_text()
            Source = a.select("div[class='XTjFC WF4CUc']")[0].get_text()
            Date = a.select("span[class='WG9SHc']")[0].get_text()

            s = {"标题": Title, "时间": Date, "来源": Source, "网页": Url}
            result_list.append(s)

        results = pd.DataFrame(result_list)
        print(results)
        return results

    def get_soup(self, query, start=2010, end=2019, num=10, page=1):
        """
        返回关键词query从start年到end年的第page页的soup
        :param query: 关键词
        :param start: 起始年份
        :param end: 终止年份
        :param num: 每页结果数量
        """
        # 休眠时间随机
        time.sleep(random.random()*6)

        # domain随机
        self.rand_url()

        # user_agent随机
        self.rand_headers()

        # ip随机
        self.rand_proxies()

        # 传入参数
        params = self.get_params(query, start, end, num, page)

        response = requests.get(self.url, headers = self.headers, params = params, proxies=self.proxies, timeout=20)
        print(response.status_code)

        # response = requests.get(self.url, headers = self.headers, params = params, timeout=60)
        demo = response.content.decode(encoding='utf-8', errors='ignore')
        soup = BeautifulSoup(demo, "lxml")

        return soup

    def rand_url(self):
        """
        随机选择一个domain，并创建一个url
        """
        #self.domain = random.choice(self.domain_list)
        self.url = "https://www.google.com/search?"
        #self.url = f"{self.domain}/search?"

    def rand_headers(self):
        """
        随机选择一个user-agent，并创建一个headers
        """
        self.headers = {
                # "user-agent": ua.random,
                "user-agent": random.choice(self.ua_list),
                "Referer": self.url[:-7],
                "accept-language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7"
            }

    def rand_proxies(self):
        """
        随机选择一个ip，并创建一个proxy
        """
        self.ip = self.read_ip_list #random.choice(self.ip_list)
        self.proxies = { 
            "http": "http://" + str(self.ip), 
            "https": "http://" + str(self.ip)
            }

    def get_params(self, query, start=2010, end=2019, num=10, page=1):
        """
        :param query: 关键词
        :param start: 起始年份
        :param end: 终止年份
        :param num: 每页结果数量
        return: requests的参数params
        """
        params = {
            "hl": "zh-CN",
            "q": query,
            "tbs": f"cdr:1,cd_min:1/1/{start},cd_max:12/31/{end},sbd:1",
            "tbm": "nws",
            "num": num,
            "start": (page - 1) * num
        }
        return params

    def read_ip_list(self):
        """
        读取保存ip的list
        """
        ip_list = ['127.0.0.1']
        # ip_list = ['127.0.0.1:10809'] # 内网ip。挂了vpn的情况下可以用这个ip访问谷歌
        #response = requests.get("http://tiqu.linksocket.com:81/abroad?num=500&type=1&lb=1&sb=0&flow=1&regions=&port=1&n=0", timeout=30)
        #ip_list = response.text.split("\r\n")

        return ip_list


    '''
    def read_domain_list(self):
        """
        读取保存domain的list
        """
        path='/Users/chupei.zhang/Desktop'
        with open(path + "/Crawler-domains.txt", "r") as f:
            domain_list = ["https://" + _.strip() for _ in f.readlines()]
            domain_list.remove("https://www.google.cn")

        return domain_list 
    '''

    def read_ua_list(self):
        """
        读取保存user-agent的list
        """
        ua_list = ['Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:25.0) Gecko/20100101 Firefox/25.0', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0',
 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:24.0) Gecko/20100101 Firefox/24.0', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10; rv:33.0) Gecko/20100101 Firefox/33.0',
 'Mozilla/5.0 (Microsoft Windows NT 6.2.9200.0); rv:22.0) Gecko/20130405 Firefox/22.0','Mozilla/5.0 (Windows NT 5.0; rv:21.0) Gecko/20100101 Firefox/21.0',
 'Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20130401 Firefox/21.0','Mozilla/5.0 (Windows NT 6.1; WOW64; rv:21.0) Gecko/20100101 Firefox/21.0',
 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:21.0) Gecko/20130330 Firefox/21.0', 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:21.0) Gecko/20130331 Firefox/21.0',
 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:23.0) Gecko/20130406 Firefox/23.0', 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:31.0) Gecko/20130401 Firefox/31.0',
 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1', 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:16.0.1) Gecko/20121011 Firefox/21.0.1',
 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:25.0) Gecko/20100101 Firefox/25.0', 'Mozilla/5.0 (Windows NT 6.1; rv:21.0) Gecko/20130328 Firefox/21.0', 'Mozilla/5.0 (Windows NT 6.1; rv:21.0) Gecko/20130401 Firefox/21.0', 'Mozilla/5.0 (Windows NT 6.1; rv:22.0) Gecko/20130405 Firefox/22.0','Mozilla/5.0 (Windows NT 6.1; rv:27.3) Gecko/20130101 Firefox/27.3', 'Mozilla/5.0 (Windows NT 6.2; WOW64; rv:21.0) Gecko/20130514 Firefox/21.0',
 'Mozilla/5.0 (Windows NT 6.2; Win64; x64; rv:16.0.1) Gecko/20121011 Firefox/21.0.1', 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0','Mozilla/5.0 (X11; Linux i586; rv:31.0) Gecko/20100101 Firefox/31.0', 'Mozilla/5.0 (X11; OpenBSD amd64; rv:28.0) Gecko/20100101 Firefox/28.0']

        return ua_list


#------------------------------------------------------------------------------------------------------------------

class BankTech():
    """
    商业银行和金融科技关键词
    """
    def __init__(self):
        self.bank_list = self.read_bank_list()
        self.fintech_list = self.read_fintech_list()

    def read_bank_list(self):
        """
        读取贷款银行的list
        """
        path='/Users/chupei.zhang/Desktop'
        with open(path + "/贷款银行清单.txt", "r") as f:
          bank_list = f.read().split()

        return bank_list

    def read_fintech_list(self):
        """
        读取金融科技的list
        """
        fintech_list = ["物联网", "人工智能", "区块链", "云计算", "大数据", "金融科技", "互联网金融", "数字金融"]

        return fintech_list

    def get_bank_words(self, num=None):
        """
        :param num: 返回list的元素个数
        change into wordcloud(text analysis?): compute the word frequency
        """
        if num == 3: # 三大政策性银行
            return ["国家开发银行", "进出口银行", "农业发展银行"]
        elif num == 5: # 五大国有商业银行
            return ["工商银行", "农业银行", "中国银行", "建设银行", "交通银行"]
        elif num == 12: # 十二大股份制商业银行
            return ["招商银行", "浦发银行", "中信银行", "光大银行", "华夏银行", "民生银行", "广发银行", "兴业银行", "平安银行", "恒丰银行", "浙商银行", "渤海银行"]
        elif num < len(self.bank_list):
            return random.sample(self.bank_list, num)
        else:
            return self.bank_list

    def get_fintech_words(self, num=None):
        """
        :param num: 返回list的元素个数
        change into wordcloud(text analysis?): compute the word frequency
        """
        if num == 3: # 三大金融科技关键词
            return ["金融科技", "互联网金融", "数字金融"]
        elif num == 5: # 五大金融科技技术关键词（iABCD）
            return ["物联网", "人工智能", "区块链", "云计算", "大数据"]
        elif num < len(self.fintech_list):
            return random.sample(self.fintech_list, num)
        else:
            return self.fintech_list
        
    def get_query(self, bank_word=None, fintech_word=None):
        # query = 'intitle:"' + bank_word + '" intext:"' + fintech_word + '"'
        if bank_word and fintech_word:
            query = 'allintext:"' + bank_word + '" "' + fintech_word + '"'
        elif bank_word:
            query = 'intext:"' + bank_word + '"'
        else:
            print("输入点东西进来啊瓜皮")
        
        return query



if __name__ == '__main__':
    googlecrawler = GoogleCrawler()
    banktech = BankTech()

    query = "工商银行"  # search word
    start = 2010
    end = 2019
    num = 10
    page = 1
    # change to mac headers
    headers = {'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36',
     'Referer': 'https://www.google.com/',
     'accept-language': 'zh-CN,zh;q=0.9'}
    params = {
                "hl": "zh-CN",
                "q": query,
                "tbs": f"cdr:1,cd_min:1/1/{start},cd_max:12/31/{end},sbd:1",
                "tbm": "nws",
                "num": num,
                "start": (page - 1) * num
            }

    time.sleep(30)
    response = requests.get("https://www.google.com/search?", headers=headers, params=params, timeout=30)
    print(response.status_code)
    #demo = response.content.decode(encoding='utf-8', errors='ignore')

    if response.status_code == 200:
        # create the soup object
        soup2 = BeautifulSoup(response.content, 'lxml')
        print("Request succeeds")
        print("-----------------")
        print(soup2)
        #soup = BeautifulSoup(response.content, 'lxml')
        # continue with the rest of your code that uses the `soup` variable
    else:
        print("Request failed with status code:", response.status_code)


    for a in soup2.find_all("a", attrs={"style":"text-decoration:none;display:block"}):
      Url = a["href"]
      Title = a.select("div[role='heading']")[0].get_text()
      Source = a.select("div[class='XTjFC WF4CUc']")[0].get_text()
      Date = a.select("span[class='WG9SHc']")[0].get_text()
      print(Url)



    googlecrawler.get_onepage_result("国家开发银行")

    bank_words = ['天津农商银行', '珠海农商银行']
    fintech_words = banktech.get_fintech_words(5)

    fintech_words = ['金融科技', '互联网金融', '数字金融']

    bank_words = [
     '大华银行',
     '长沙银行',
     '国家开发银行',
     '进出口银行',
     '大连银行',
     '烟台银行',
     '渤海银行',
     '广州农商银行',
     '齐鲁银行',
     '温州银行',
     '成都农商银行',
     '西安银行',
     '北京银行',
     '珠海农商银行',
     '徽商银行',
     '青海银行',
     '平安银行',
     '中信银行',
     '交通银行',
     '龙江银行',
     '廊坊银行',
     '吉林银行',
     '中国银行',
     '杭州联合农商银行',
     '渣打银行',
     '晋商银行',
     '河北银行',
     '工商银行',
     '哈尔滨银行',
     '法国兴业银行',
     '昆仑银行',
     '锦州银行',
     '贵阳银行',
     '江苏紫金农商银行',
     '华夏银行',
     '南洋商业银行',
     '宁夏银行',
     '中信信托',
     '江西银行',
     '农业银行',
     '汉口银行',
     '恒生银行',
     '潍坊银行',
     '青岛银行',
     '无锡农商银行',
     '九江银行',
     '建设银行',
     '贵州银行',
     '兴业银行',
     '华兴银行',
     '深圳农商银行',
     '郑州银行',
     '华润银行',
     '杭州银行',
     '乌鲁木齐银行',
     '江苏江南农商银行',
     '中原银行',
     '厦门农商银行',
     '江苏银行',
     '浦发银行',
     '浙商银行',
     '恒丰银行',
     '上海农商银行',
     '张家港农商银行',
     '苏州银行',
     '成都银行',
     '上海银行',
     '平顶山银行',
     '武汉农商银行',
     '韩亚银行',
     '重庆三峡银行',
     '厦门国际银行',
     '洛阳银行',
     '湖北银行',
     '重庆银行',
     '齐商银行',
     '北京农商银行',
     '绵阳市商业银行',
     '长安银行',
     '广州银行',
     '农业发展银行',
     '甘肃银行',
     '华美银行',
     '邮政储蓄银行',
     '东莞银行',
     '东亚银行',
     '光大银行',
     '桂林银行',
     '星展银行',
     '日照银行',
     '泉州银行',
     '德意志银行',
     '华融湘江银行',
     '广发银行',
     '招商银行',
     '重庆农商银行',
     '南京银行',
     '宁波银行',
     '天津农商银行',
     '北部湾银行',
     '盛京银行',
     '合肥科技农商银行',
     '兰州银行',
     '澳新银行',
     '顺德农商银行',
     '民生银行',
     '赣州银行',
     '天津银行',
     '沧州银行',
     '厦门银行']

    key_words = [(bank, fintech) for bank in bank_words for fintech in fintech_words]

    for bank, fintech in key_words:
         query = banktech.get_query(bank, fintech)

         result = googlecrawler.get_allpages_result(query=query, start=2010, end=2019, num=20)
         path='/Users/chupei.zhang/Desktop'
         result.to_excel(path + "/0208_Results2_Details-" + bank + "-" + fintech + ".xlsx", index=False)

         print("/0208_Results2_Details-" + bank + "-" + fintech+' done!')

print('All done!')

