import os
from cumulusci.tasks.salesforce import UpdateProfile as BaseUpdateProfile
from cumulusci.utils.xml import metadata_tree
from cumulusci.tasks.salesforce import BaseSalesforceApiTask


class UpdateProfile(BaseUpdateProfile):


    def _transform_entity(self, tree, api_name):

        with open(self.package_xml_path, "r") as f:
                package_xml_content = f.read()

        res = self.sf.query('SELECT NamespacePrefix FROM Organization')
        namespace_prefix = res["records"][0]["NamespacePrefix"]

        package_xml_content = package_xml_content.format(**self.namespace_prefixes)
        package_xml_content = package_xml_content.replace(self.project_config.project__package__namespace,namespace_prefix)
        package_xml = metadata_tree.fromstring(
                    package_xml_content.encode("utf-8")
        )
        # Custom applications
        self._set_elements_visible(tree, "applicationVisibilities", "visible")
        # Apex classes
        # self._set_elements_visible(tree, "classAccesses", "enabled")
        # Fields
        # self._set_elements_visible(tree, "fieldPermissions", "editable")
        # self._set_elements_visible(tree, "fieldPermissions", "readable")
        # Visualforce pages
        self._set_elements_visible(tree, "pageAccesses", "enabled")
        # Custom tabs
        self._set_elements_visible(
            tree,
            "tabVisibilities",
            "visibility",
            false_value="Hidden",
            true_value="DefaultOn",
        )
        # Record Types
        self._set_record_types(tree, api_name)

        custom_objects = package_xml.find("types", name="CustomObject")

        for record in custom_objects["members"]:
                element = tree.append("objectPermissions")
                element.append("object", text=str(record.text))
                element.append(
                    "allowRead", "true"
                )
                element.append(
                    "allowEdit", "true"
                )
                element.append(
                    "allowCreate", "true"
                )
                element.append(
                    "allowDelete", "true"
                )

        custom_field = package_xml.find("types", name="CustomField")

        for record in custom_field["members"]:
                element = tree.append("fieldPermissions")
                element.append("field", text=str(record.text))
                element.append(
                    "readable", "true"
                )
                element.append(
                    "editable", "true"
                )

        apex_class = package_xml.find("types", name="ApexClass")

        for record in apex_class["members"]:
                element = tree.append("classAccesses")
                element.append("apexClass", text=str(record.text))
                element.append(
                    "enabled", "true"
                )

        return tree
