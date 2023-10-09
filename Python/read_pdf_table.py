# -*- coding: utf-8 -*-
"""
Extracting credit line data

@author: Eveline Chupei Zhang
"""


import camelot
import csv
import PyPDF2
import os
import itertools



def get_credit_line(file_dir, output_csv):
  header=['time', 'company_id', 'company_name', 'Name_of_Provider', 'Credit_Limit', 'Remaining_Credit']
  # write the credit line data into a csv file
  with open(output_csv, 'a', newline='') as f:
      writer = csv.writer(f)
      writer.writerow(header)
  
  
  # read all the pdf files under one directory
  for files in os.walk(file_dir):
      for file in files[2]:
          if os.path.splitext(file)[1]=='.PDF' or os.path.splitext(file)[1]=='.pdf':
              filename=file_dir+file
              print(filename)
  
              # get time
              time=[]
              pdf_file = open(filename, 'rb')
              # Create a PDF reader object
              pdf_reader = PyPDF2.PdfReader(pdf_file)
              # Get the page object
              page_obj = pdf_reader.pages[0]
              # Extract the text from the page object
              page_text = page_obj.extract_text()
              # print(page_text)
              pdf_file.close()
              text = page_text.split()
              time_str = " ".join(text[:2])
              time.append(time_str)
  
              # get company_name and company_id
              company_name=[]
              company_id=[]
              start_index = text.index('for')
              end_index = text.index('submitted')
  
              company_name_str=" ".join(text[start_index+1:end_index-1])
              company_id_str=" ".join(text[end_index-1]).replace('(','').replace(')','').replace(' ','')
              print(company_name_str+'; '+company_id_str)
  
              company_name.append(company_name_str)
              company_id.append(company_id_str)
  
              # get credit line data
              table = camelot.read_pdf(filename, pages='1',flavor='stream')
              print(len(table[0].data))
  
              if len(table[0].data)<=14:
                  table=table[0].data[4:]
  
                  Name_of_Provider = [e[2] for e in table]
                  print(Name_of_Provider)
  
                  Credit_Limit = [e[3] for e in table]
                  print(Credit_Limit)
  
                  Remaining_Credit = [e[4] for e in table]
                  print(Remaining_Credit)
  
              else:
                  if ['Attestation', '', '', '', '', ''] in table[0].data:
                      index=table[0].data.index(['Attestation', '', '', '', '', ''])
                      table = table[0].data[9:index]
                      print(table)
  
                      Name_of_Provider = [e[2] for e in table]
                      print(Name_of_Provider)
  
                      Credit_Limit = [e[3] for e in table]
                      print(Credit_Limit)
  
                      Remaining_Credit = [e[4] for e in table]
                      print(Remaining_Credit)
  
                  else:
                      index=table[0].data.index(['Attestation'])
                      #print(index)
  
                      table=table[0].data[9:index]
                      for list in table:
                          table_info=list[0].replace('\n',';')
                          info_list=table_info.split(";")
                          info_list_combine=[]
                          info_list_combine.append(info_list)
                          print(info_list_combine)
  
                          Name_of_Provider = [e[1] for e in info_list_combine]
                          print(Name_of_Provider)
  
                          Credit_Limit = [e[2] for e in info_list_combine]
                          print(Credit_Limit)
  
                          Remaining_Credit = [e[3] for e in info_list_combine]
                          print(Remaining_Credit)
  
          time *= len(Name_of_Provider)
          company_name *= len(Name_of_Provider)
          company_id *= len(Name_of_Provider)
          info_rows = itertools.zip_longest(time, company_id, company_name, Name_of_Provider, Credit_Limit, Remaining_Credit)
  
          # write the credit line data into a csv file
          with open(output_csv, 'a', newline='') as f:
              writer = csv.writer(f)
              for row in info_rows:
                  writer.writerow(row)
          print("done!")
        


if __name__=='__main__':
  file_dir = "/dataset/raw_data/"  # change the file path
  output_csv='credit_line.csv'

  get_credit_line(file_dir, output_csv)
  
  print('All PDFs done!')




