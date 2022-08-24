import os
from cumulusci.tasks.salesforce import UpdateDependencies as BaseUpdateDependencies
from cumulusci.utils import find_replace
from cumulusci.utils import find_replace_regex
import requests

packagedata = requests.get("https://fonteva-marketplace-automation.herokuapp.com/api/packages?all=true").json()

class UpdateDependencies(BaseUpdateDependencies):

      def _init_options(self, kwargs):
        super(UpdateDependencies, self)._init_options(kwargs)
        dependencies = []
        allPackages = ['Framework','KEYSTORE','PagesApi','OrderApi','EventApi','FDService','FDSSPR20','ROEApi','LTE','CPBase','DonorApi','FontevaCom','Fonteva1']
        for nsp in allPackages:
            for element in packagedata['data']:
                 if element['namespace'] == nsp:
                    dependencies.append({'namespace': element['namespace'], 'version': element['version']})
        kwargs["dependencies"] = dependencies
        super(UpdateDependencies, self)._init_options(kwargs)
