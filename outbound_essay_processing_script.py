import sys
import os
import shutil
from pandas import DataFrame
import pandas as pd
from lxml import etree, objectify
import time

"""
BEGIN Script configuration settings.  
"""
#[OPTIONAL] The directory to find output from model.  If passed as parameter, this will be ignored.  If blank, user will be prompted to enter.
from_model = "/frommodel/"

#[OPTIONAL] The directory to post XML files ready for CTB, AKA "topems".  If passed as parameter, this will be ignored.  If blank, user will be prompted to enter.
topems = "/topems"

# The name of folder to store from_model files after processing. 
from_model_sent = "from_model_sent" 

# The reader ID to for scoring model
reader_id = "222"

"""
END Script configuration settings.  
"""


#Logic to determine if directory instructions are passed in as script parameter, defined in script, or should be prompted for.
if len(sys.argv) == 3:
    from_model = sys.argv[1] 
    topems = sys.argv[2] 
    
else:
    try:
        from_model 
    except NameError:   
         print "What is the path for files from model to process?"
         from_model = raw_input("> ")
    try:
        topems
    except NameError:   
         print "What is the path for XML files ready for CTB?"
         topems = raw_input("> ")

# Check if folders exist and if not, then exit.
if os.path.isdir(from_model) == False: sys.exit("Please check source directory, e.g.'frompems', then try again.")
if os.path.isdir(topems) == False: sys.exit("Please check source directory, e.g. 'topems' then try again.")


#create directory for csv files after processing if doesn't already exist
f_m_sdir = os.path.join(from_model,from_model_sent)
if os.path.isdir(f_m_sdir) == False: os.mkdir(f_m_sdir)


#create list of to-process csv files
csvfiles = [ f for f in os.listdir(from_model) if f.endswith(".csv") ]


#process the csv files into xml
for csvfile in csvfiles:
    #read CSV file into pandas dataframe
    fileframe = pd.read_csv(os.path.join(from_model,csvfile), index_col="Ven_Stud_ID")
    
    # Extract job details from the first row of data
    JD_Score_Provider_Name = str(fileframe.iloc[0].loc["AI_Prov_Name"])
    JD_Case_Count = str(fileframe.iloc[0].loc["File_Count"])
    JD_Date_Time = str(fileframe.iloc[0].loc["File_Date"])

    # Set XML root details
    root = objectify.fromstring('''\
        <Job_Details xmlns="http://www.imsglobal.org/xsd/imscp_v1p1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="ctb_score.xsd" />
     ''')
    root.set('Score_Provider_Name', JD_Score_Provider_Name) 
    root.set('Case_Count', JD_Case_Count)
    root.set('Date_Time', JD_Date_Time)

    for row_index, row in fileframe.iterrows():
        # Student_Details as node of Job_Details
        SD = etree.SubElement(root, "Student_Details", Vendor_Student_ID=str(row_index))

        # Student_Test_List as subnode of Student_Details
        STL = etree.SubElement(SD, "Student_Test_List")

        # Student_Test_Details as subnode of Student_Test_List
        STD = etree.SubElement(STL, "Student_Test_Details", Student_Test_ID=str(row.loc["Stud_Test_ID"]), Grade=str(row.loc["Grade"]), Total_CR_Item_Count="1")

        # Item_Data_Point_List as subnode of Student_Test_Details
        IDPL = etree.SubElement(STD, "Item_DataPoint_List")


        # Item_DataPoint_Details for Data_Point = A as subnode of Item_DataPoint_List
        IDPD_A = etree.SubElement(IDPL, "Item_DataPoint_Details", Item_ID=str(row.loc["Item_ID"]), Data_Point="A", Item_No="1", Final_Score=str(int(round(row.loc["prediction_A"]))))
        # Read_Details as subnode of Item_DataPoint_Details
        RD = etree.SubElement(IDPD_A, "Read_Details",Read_Number="1", Score_Value=str(int(round(row.loc["prediction_A"]))), Reader_ID=reader_id, Date_Time=time.strftime("%Y%m%d%H%M%S"))


        # Item_DataPoint_Details for Data_Point = B as subnode of Item_DataPoint_List
        IDPD_B = etree.SubElement(IDPL, "Item_DataPoint_Details", Item_ID=str(row.loc["Item_ID"]), Data_Point="B", Item_No="1", Final_Score=str(int(round(row.loc["prediction_B"]))))
        # Read_Details as subnode of Item_DataPoint_Details
        RD = etree.SubElement(IDPD_B, "Read_Details",Read_Number="1", Score_Value=str(int(round(row.loc["prediction_B"]))), Reader_ID=reader_id, Date_Time=time.strftime("%Y%m%d%H%M%S"))


        # Item_DataPoint_Details for Data_Point = C as subnode of Item_DataPoint_List
        IDPD_C = etree.SubElement(IDPL, "Item_DataPoint_Details", Item_ID=str(row.loc["Item_ID"]), Data_Point="C", Item_No="1", Final_Score=str(int(round(row.loc["prediction_C"]))))
        # Read_Details as subnode of Item_DataPoint_Details
        RD = etree.SubElement(IDPD_C, "Read_Details",Read_Number="1", Score_Value=str(int(round(row.loc["prediction_C"]))), Reader_ID=reader_id, Date_Time=time.strftime("%Y%m%d%H%M%S"))


    target = open(os.path.join(topems,os.path.splitext(csvfile)[0]+".xml"), 'w')
    target.write(etree.tostring(root, encoding='UTF-8', xml_declaration=True, pretty_print=True))
    target.close()
        
    shutil.move(os.path.join(from_model,csvfile),f_m_sdir)