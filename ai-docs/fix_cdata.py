#!/usr/bin/env python3
"""Fix nested CDATA sections in overview.xml"""
import re

with open("overview.xml", "r") as f:
    content = f.read()

# Fix nested CDATA
content = content.replace("<![CDATA[<![CDATA[", "<![CDATA[")
content = content.replace("]]>]]>", "]]>")

with open("overview.xml", "w") as f:
    f.write(content)
print("Fixed CDATA nesting in overview.xml")
