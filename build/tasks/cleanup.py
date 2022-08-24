import os
import shutil

from cumulusci.core.tasks import BaseTask

class cleanUp(BaseTask):
    def _run_task(self):
        if os.path.exists('./tmp'):
            shutil.rmtree('./tmp')
            self.logger.info("Deleted ./tmp directory")
