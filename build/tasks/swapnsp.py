from cumulusci.tasks.salesforce import BaseSalesforceApiTask
import re
import os
import shutil

class SwapNsp(BaseSalesforceApiTask):
    def _run_task(self):
        res = self.sf.query('SELECT NamespacePrefix FROM Organization')
        srcPath = self.options.get("src_path")
        destPath = self.options.get("dest_path")
        if not srcPath or not os.path.exists(srcPath):
            raise TaskOptionsError(
                "The src path needs to be provided."
            )
        if not destPath or not os.path.exists(destPath):
            destPath = './tmp'

        findStr= self.project_config.project__package__namespace
        replace_with= res["records"][0]["NamespacePrefix"]
        self.logger.info("Replacing " + findStr + " to " + replace_with)
        self.findReplace(srcPath , findStr ,replace_with , destPath)

    def findReplace(self,sourcedir, find, replace, targetdir):
        if os.path.exists('./tmp'):
            shutil.rmtree('./tmp')
        shutil.copytree(sourcedir, targetdir) #we will create a backup of it
        pattern = re.compile(find)
        for dirpath, dirname, filename in os.walk(targetdir):#Getting a list of the full paths of files
            for fname in filename:
                path = os.path.join(dirpath, fname) #Joining dirpath and filenames
                strg = open(path,encoding="utf8", errors='ignore').read() #Opening the files for reading only
                if re.search(pattern, strg):#If we find the pattern ....
                    prodNsp = find + '__'
                    devNsp = replace + '__'
                    strg = strg.replace(prodNsp, devNsp) #We will create the replacement condition
                if 'classes' not in dirpath:
                    path = os.path.join(dirpath, fname) #Joining dirpath and filenames
                    strg = open(path,encoding="utf8", errors='ignore').read() #Opening the files for reading only
                    if re.search(pattern, strg):#If we find the pattern ....
                        prodNsp = find + '__'
                        devNsp = replace + '__'
                        prodComp = find + ':'
                        devComp = replace + ':'
                        strg = strg.replace(prodNsp, devNsp) #We will create the replacement condition
                        strg = strg.replace(prodComp, devComp) #We will create the replacement condition
                        strg = strg.replace("c:", devComp) #We will create the replacement condition
                f = open(path,'w') #We open the files with the WRITE option
                f.write(strg) # We are writing the the changes to the files
                f.close() #Closing the files
