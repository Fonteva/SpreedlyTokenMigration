import os
from cumulusci.tasks.salesforce import UpdateDependencies as BaseUpdateDependencies
from cumulusci.utils import find_replace
from cumulusci.utils import find_replace_regex
import requests

class UpdateDependencies(BaseUpdateDependencies):
   def _init_options(self, options):
      super(UpdateDependencies, self)._init_options(options)
      dependencies = []
      patchVersion = self.options.get("patchVersion")
      packageData = requests.get("https://fonteva-marketplace.herokuapp.com/api/package/patch_packages?version="+patchVersion).json()

      packages = {}

      for pkg in packageData:
         packages[pkg['namespace']] = pkg

      packages.setdefault('LTE', packages.get('ROEApi', packages.get('CPBase')))
      packages.setdefault('ROEApi', packages.get('LTE', packages.get('CPBase')))
      packages.setdefault('CPBase', packages.get('LTE', packages.get('ROEApi')))
      
      projectPackage = packages.get(self.project_config.project__package__namespace)

      if projectPackage is not None:
         for dep in projectPackage['fullDependencies']:
            dependencies.append({
               'namespace': dep['namespace'].strip(),
               'version': dep['version'].strip()
            })

      options["dependencies"] = dependencies
      print(dependencies)
      super(UpdateDependencies, self)._init_options(options)
