import os
from cumulusci.tasks.salesforce import UpdateDependencies as BaseUpdateDependencies
from cumulusci.utils import find_replace
from cumulusci.utils import find_replace_regex
import requests


class UpdateDependencies(BaseUpdateDependencies):

      def _init_options(self, kwargs):
        super(UpdateDependencies, self)._init_options(kwargs)
        dependencies = []
        patchVersion = self.options.get("patchVersion")
        packagedata = requests.get("https://fonteva-marketplace.herokuapp.com/api/package/patch_packages?version="+patchVersion).json()
        allPackages = ['Framework','KEYSTORE','PagesApi','OrderApi','EventApi','FDService','FDSSPR20', "FDS19R2",
            "FDS19R1A","FDS18R2",'ROEApi','LTE','CPBase','DonorApi','FontevaCom','Fonteva1']
        for nsp in allPackages:
            for element in packagedata:
                 if element['namespace'] == nsp:
                    dependencies.append({'namespace': element['namespace'], 'version': element['version']})
        kwargs["dependencies"] = dependencies
        super(UpdateDependencies, self)._init_options(kwargs)
