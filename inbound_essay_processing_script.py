import sys
import os
import zipfile
import shutil
from pandas import DataFrame
from lxml import etree


"""
BEGIN Script configuration settings.  
"""
#[OPTIONAL] The directory to find files from CTB, AKA "frompems".  If passed as parameter, this will be ignored.  If blank, user will be prompted to enter.
frompems = "/frompems/"

#[OPTIONAL] The directory to put folders of files after processing.  If passed as parameter, this will be ignored.  If blank, user will be prompted to enter.
processed = "/inbound/wip/"

# The name of folder to put zip files after extraction 
compressed = "frompems_compressed" 

# The name of folder to put tsv files 
tsv = "to_model"

# The name of folder to put pickle files
pickle = "frompems_pickle"

# The name of folder to put xml files
xml ="frompems_xml"

"""
END Script configuration settings.  
"""


#Logic to determine if directory instructions are passed in as script parameter, defined in script, or should be prompted for.
if len(sys.argv) == 3:
    frompems = sys.argv[1]  
    processed = sys.argv[2] 
    
else:
    try:
        frompems 
    except NameError:   
         print "What is the path for files frompems?"
         frompems = raw_input("> ")
    try:
        processed
    except NameError:   
         print "What is the path to stores files after processing?"
         processed = raw_input("> ")


# Check if folders exist and if not, then exit.
if os.path.isdir(processed) == False: sys.exit("Please create destination directory then try again.")
if os.path.isdir(frompems) == False: sys.exit("Please check source directory, e.g.'frompems', then try again.")


#create directory for zip files after decompression
commdir = os.path.join(processed, compressed)
if os.path.isdir(commdir) == False: os.mkdir(commdir)

#create directory for tab seperated files after creation
tsvdir = os.path.join(processed, tsv)
if os.path.isdir(tsvdir) == False: os.mkdir(tsvdir)

#create directory for pickle files after creation
pickledir = os.path.join(processed, pickle)
if os.path.isdir(pickledir) == False: os.mkdir(pickledir)

#create directory for xml files after processing
xmldir = os.path.join(processed, xml)
if os.path.isdir(xmldir) == False: os.mkdir(xmldir)

#list of columns names for tsv and pickle files
columns = [
    'AI_Prov_Name',
    'File_Date',
    'File_Count',
    'Group_Count',
    'Ethnicity',
    'IEP',
    'LEP',
    'Gender',
    'Ven_Stud_ID',
    'Grade',
    'Stud_Test_ID',
    'Score_Flag',
    'Item_ID',
    'Item_Response',

    #*******Scored items********
    'Data_Point_A',
    'Final_Score_A',
    'Read1_Date_A',
    'Read1_ID_A',
    'Read1_Score_A',
    'Read1_Cond_A',
    'Read2_Date_A',
    'Read2_ID_A',
    'Read2_Score_A',
    'Read2_Cond_A',
    'Read3_Date_A',
    'Read3_ID_A',
    'Read3_Score_A',
    'Read3_Cond_A',
    'Read5_Date_A',
    'Read5_ID_A',
    'Read5_Score_A',
    'Read5_Cond_A',

    'Data_Point_B',
    'Final_Score_B',
    'Read1_Date_B',
    'Read1_ID_B',
    'Read1_Score_B',
    'Read1_Cond_B',
    'Read2_Date_B',
    'Read2_ID_B',
    'Read2_Score_B',
    'Read2_Cond_B',
    'Read3_Date_B',
    'Read3_ID_B',
    'Read3_Score_B',
    'Read3_Cond_B',
    'Read5_Date_B',
    'Read5_ID_B',
    'Read5_Score_B',
    'Read5_Cond_B',

    'Data_Point_C',
    'Final_Score_C',
    'Read1_Date_C',
    'Read1_ID_C',
    'Read1_Score_C',
    'Read1_Cond_C',
    'Read2_Date_C',
    'Read2_ID_C',
    'Read2_Score_C',
    'Read2_Cond_C',
    'Read3_Date_C',
    'Read3_ID_C',
    'Read3_Score_C',
    'Read3_Cond_C',
    'Read5_Date_C',
    'Read5_ID_C',
    'Read5_Score_C',
    'Read5_Cond_C',

    'Alert_Code_1',
    'Alert_ReaderID_1',
    'Alert_Code_2',
    'Alert_ReaderID_2',
    ]

data_point_values = {'A','B','C'}

#decompress zip files and move zip files to zip directory
zipfiles = [ f for f in os.listdir(frompems) if f.endswith(".zip") ]

for zfile in zipfiles:
    z = zipfile.ZipFile(os.path.join(frompems,zfile))
    z.extractall(path=frompems)
    z.close()
    shutil.move(os.path.join(frompems,zfile),commdir)


#create list of xml files
xmlfiles = [ f for f in os.listdir(frompems) if f.endswith(".xml") ]


#parse the XML files
for xfile in xmlfiles:
    tree = etree.parse(open(os.path.join(frompems,xfile)))
    root = tree.getroot()

    data = []

    for elt in root.getiterator('Item_Details'):
        el_data = {}

        el_data['Score_Flag'] = elt.get('Score')
        el_data['Item_ID'] = elt.get('Item_ID')

        #read ancestor data
        IL = elt.getparent() # Item List
        STD = IL.getparent() # Student_Test_Details
        STL = STD.getparent() # Student_Test_List
        SD = STL.getparent() # Student_Details
        SL = SD.getparent() # Student_List
        GD = SL.getparent() # Group_Details
        GL = GD.getparent() # Group_List
        JD = GL.getparent() # Job_Details
        el_data['Grade'] = STD.get('Grade')
        el_data['Stud_Test_ID'] = STD.get('Student_Test_ID')
        el_data['Ethnicity'] = SD.get("Ethnicity")
        el_data['IEP'] = SD.get("IEP")
        el_data['LEP'] = SD.get("LEP")
        el_data['Gender'] = SD.get("Gender")
        el_data['Ven_Stud_ID'] = SD.get("Vendor_Student_ID")
        el_data['Group_Count'] = GD.get("Case_Count")
        el_data["AI_Prov_Name"] = JD.get("AI_Score_Provider_Name")
        el_data["File_Date"] = JD.get("Date_Time")
        el_data["File_Count"] = JD.get("Case_Count")

        #read descendant data
        IR = elt.find('Item_Response')
        response_text = IR.text.rstrip()
        response_text = response_text.replace("&nbsp;"," ")
        response_text = response_text.replace("&quot;","'")
        response_text = response_text.replace("<p>"," ")
        response_text = response_text.replace("</p>"," ")
        response_text = response_text.replace("<b>","")
        response_text = response_text.replace("</b>","")
        response_text = response_text.replace("<u>","")
        response_text = response_text.replace("</u>","")
        response_text = response_text.replace("<i>","")
        response_text = response_text.replace("</i>","")
        response_text = response_text.replace("<br>","")

        el_data['Item_Response'] = response_text

        for IDPSD in elt.getiterator('Item_DataPoint_Score_Details'):
            data_point = IDPSD.get("Data_Point")
            if data_point in data_point_values:
                el_data['Final_Score_'+data_point] = IDPSD.get("Final_Score")
                el_data['Data_Point_'+data_point] = data_point

                for score in IDPSD.getiterator('Score'):
                    read = score.get('Read_Number')
                    el_data['Read'+read+'_Date_'+data_point] = score.get("Date_Time")
                    el_data['Read'+read+'_ID_'+data_point] = score.get("Reader_ID")
                    el_data['Read'+read+'_Score_'+data_point] = score.get("Score_Value")
                    el_data['Read'+read+'_Cond_'+data_point] = score.get("Condition_Code")
            else:
                print "unknown data point encountered."

        alert_count = 0
        for child in elt.getiterator('Item_Alert'):
            alert_count += 1
            el_data['Alert_Code_'+str(alert_count)] = child.get("Alert_Code")
            el_data['Alert_ReaderID_'+str(alert_count)] = child.get("Alert_ReaderID")

        #add element data to the file-level data
        data.append(el_data)
        print len(data)

    #convert into a DataFrame then save as pickle, csv, then move XML to processed directory.
    fileframe = DataFrame(data, columns=columns)
    fileframe.to_pickle(os.path.join(pickledir,os.path.splitext(xfile)[0]+".pickle")) #pickle files useful for further python processing
    fileframe.to_csv(os.path.join(tsvdir,os.path.splitext(xfile)[0]+".tsv"), sep="\t") #tsv files to be used for input to R scripts
    shutil.move(os.path.join(frompems,xfile),xmldir) #move XML to processed XML directory


