import os
import shutil

from cumulusci.core.tasks import BaseTask

class cleanUp(BaseTask):
    def _run_task(self):
        if os.path.exists('./.cci/projects/ApexMocks'):
            shutil.rmtree('./.cci/projects/ApexMocks')
            self.logger.info("Deleted ApexMocks directory")

        if os.path.exists('./.cci/projects/Data-Access-Library'):
            shutil.rmtree('./.cci/projects/Data-Access-Library')
            self.logger.info("Deleted Data-Access-Library directory")
