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
        for element in packagedata['data']:
             if element['namespace'] == self.project_config.project__package__namespace:
                 for dep in element['fullDependencies']:
                    dependencies.append({'namespace': dep['namespace'], 'version': dep['version']})
        kwargs["dependencies"] = dependencies
        super(UpdateDependencies, self)._init_options(kwargs)
