-- XSD.lua module test file

xsdFile = "Task_Spore.xsd"
xmlFiles = {[1] = "Test_Spore.xml"}
require("XSD")

O = XSD:new(xsdFile, xmlFiles)

print("O's XSD file is ".. O:xsdFile())
print("O's xml files are: ")
table.foreach(O:xmlFiles(),print)
print("O's XSD structure is:")
print(O:xsdStruct())
