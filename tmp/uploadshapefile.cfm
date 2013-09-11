<cfsetting requesttimeout="600">
<cfparam name="fileDirectory" default="/tmp/spatialkey.csvtoumg.tmp/"/>
<cfparam name="form.file" default=""/>
<cfparam name="clusterLookup" default="true">
<cfif form.file neq "">
   <!--- upload file and get results --->
   <cffile action="upload"
      filefield="file"
      destination="#fileDirectory#"
      nameconflict="makeunique"
      result="uploadResult">
   <cfoutput>Final upload location: #fileDirectory##uploadResult.serverFile#<br /></cfoutput>
	<cfscript>
		if (uploadResult.fileWasSaved)
		{
			objSKdp=createObject('component','SK_DataPublisherAPI');
	
			 /* login */
			 objSKdp.login(hostname=form.hostname,username=form.username,password=form.password,doClusterLookup=clusterLookup);
				
			 /* upload polygon shape .zip */
			 uploadedFile = 
			 objSKdp.uploadPolygons(file=fileDirectory & uploadResult.serverFile,datasetName=form.datasetname);
		}
   	</cfscript>
</cfif>

<html>
<head>
<title>Upload Shape file</title>
</head>

<body>

<!--- upload form --->
Select a file to upload:<br />
<form method="post" action="<cfoutput>#cgi.SCRIPT_NAME#?#cgi.QUERY_STRING#</cfoutput>" enctype="multipart/form-data">
   	<b>Host Name:</b> <input name="hostname" id="hostname" size="40"/></br>
	<b>User Name:</b> <input name="username" id="username" size="40"/></br>
	<b>Password:</b> <input name="password" id="password" size="40" type="password"/></br>
	<b>Upload File:</b> <input type="file" name="file" id="file" size="40"/></br>
	<b>Dataset Name:</b> <input name="datasetname" id="datasetname" size="40"/></br>
   	<input type="submit" name="button" id="button" value="Submit" />
</form>

</body>
</html>