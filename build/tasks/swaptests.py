from cumulusci.core.tasks import BaseTask
import re
import os
import shutil

class SwapTests(BaseTask):
    def _run_task(self):
        srcPath = self.options.get("src_path")
        destPath = self.options.get("dest_path")
        if not srcPath or not os.path.exists(srcPath):
            raise Exception(
                "The src path needs to be provided."
            )
        if not destPath or not os.path.exists(destPath):
            destPath = './tmp'

        findStr= '(?i)@isTest\s.*static'
        replace_with= 'static'
        self.findReplace(srcPath ,findStr ,replace_with, destPath)
    
    def check_if_string_in_file(self,file_name, string_to_search):
    # Open the file in read only mode
        with open(file_name, 'r') as read_obj:
            # Read all lines in the file one by one
            for line in read_obj:
                # For each line, check if line contains the string
                if string_to_search in line:
                    return True
        return False

    def findReplace(self,sourcedir, find, replace, targetdir):
        if os.path.exists('./tmp'):
            shutil.rmtree('./tmp')
        shutil.copytree(sourcedir, targetdir) #we will create a backup of it
        pattern = re.compile(find)
        cwd = os.getcwd()
        file_name = cwd + '/swaptestsList.txt'
        for dirpath, dirname, filename in os.walk(targetdir):#Getting a list of the full paths of files
            for fname in filename:
                if 'classes' in dirpath:
                    if fname.startswith('Test_'):
                        if self.check_if_string_in_file(file_name,fname):
                            self.logger.info(fname)
                            path = os.path.join(dirpath, fname) #Joining dirpath and filenames
                            strg = open(path,encoding="utf8", errors='ignore').read() #Opening the files for reading only
                            if re.search(pattern, strg):#If we find the pattern ....
                                strg = re.sub(find,replace,strg) #We will create the replacement condition
                                f = open(path,'w') #We open the files with the WRITE option
                                f.write(strg) # We are writing the the changes to the files
                                f.close() #Closing the files
