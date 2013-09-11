<cfscript>
 objSKdp=createObject('component','SK_DataPublisherAPI');
 currDir = GetDirectoryFromPath(GetCurrentTemplatePath());
 currDir = '/Users/universalmind/Documents/spatialkey/customers/louisville/';
 xmlFile= currDir & 'Trct62MashXY.xml';
 csvFile= currDir & 'Trct62MashXY.csv';
 //zipFile= currDir & 'SalesData.zip';
	
 /* login */
 objSKdp.login(hostname='demos.spatialkey.com',username='test.user@spatialkey.com',password='pass.word',doClusterLookup='false');
	
 /* example uploading both a CSV and XML */ 
 objSKdp.upload(csvfile=csvFile,xmlfile=xmlFile,action='overwrite');
 
 /* zip example */
 //objSKdp.upload(zipfile=csvFile,action='overwrite');
</cfscript>




	