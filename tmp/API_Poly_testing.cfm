Poly Testing 
<cfsetting requesttimeout="240">
<cfscript>
 objSKdp=createObject('component','SK_DataPublisherAPI');
 //objSKdp.clusterURL="localhost";
	
 /* login */
//objSKdp.login(hostname='louisvillemetronsp.spatialkey.com',username='brandon.purcell@universalmind.com',password='Purcell69',doClusterLookup='true');
	
//objSKdp.login(hostname='demos.spatialkey.com',username='test.user@spatialkey.com',password='pass.word',doClusterLookup='false');

//anthonys box
//objSKdp.login(hostname='um2.spatialkey.com',username='Administrator@universalmind.com',password='UM!1s_gre@t!',doClusterLookup='false',port=8080);
//dev
//objSKdp.login(hostname='dev3.spatialkey.com',username='anthony.mcclure@spatialkey.com',password='1Seteshf00d',doClusterLookup='true');
//cluster 2 test
objSKdp.login(hostname='brandon.spatialkey.com',username='anthony.mcclure@spatialkey.com',password='1Seteshf00d',doClusterLookup='false',protocol='http://',port=7080,url='cluster2.spatialkey.com');
	

 /* upload polygon shape .zip */
 //
//objSKdp.uploadPolygons(file='/Users/amcclure/Downloads/all_hurtrack.zip',datasetName='API Shapefile Test');
objSKdp.uploadPolygons(file='/Users/amcclure/Downloads/BUS_AND_TRAIN_3-7-06.zip',datasetName='BUS API Shapefile Test (small)');

//objSKdp.uploadPolygons(file='/Users/universalmind/Documents/spatialkey/shape files/ogden/Police_Districts.zip',datasetName='Weber County Police Districts API Update');


</cfscript>