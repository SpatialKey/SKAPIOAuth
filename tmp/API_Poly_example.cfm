<cfscript>
 objSKdp=createObject('component','SK_DataPublisherAPI');
 objSKdp.clusterURL="localhost";
	
 /* login */
 objSKdp.login(hostname='um2.spatialkey.com',username='Administrator@universalmind.com',password='',doClusterLookup='true');
	
 /* upload polygon shape .zip */
 objSKdp.uploadPolygons(file='/Users/universalmind/tmp/police_districts.zip',datasetName='Ogden Police Districs Test');
</cfscript>
	