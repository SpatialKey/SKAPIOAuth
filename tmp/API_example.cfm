<cfscript>
 objSKdp=createObject('component','SK_DataPublisherAPI');
 currDir = GetDirectoryFromPath(GetCurrentTemplatePath());
 xmlFile= currDir & 'SalesData.xml';
 csvFile= currDir & 'SalesData.csv';
 zipFile= currDir & 'SalesData.zip';
	
 /* login */
 objSKdp.login(hostname='mysite.spatialkey.com',username='un',password='pw',doClusterLookup='true');
	
 /* example uploading both a CSV and XML */ 
 objSKdp.upload(csvfile=csvFile,xmlfile=xmlFile,action='overwrite');
 
 /* zip example */
 objSKdp.upload(zipfile=csvFile,action='overwrite');
</cfscript>




	