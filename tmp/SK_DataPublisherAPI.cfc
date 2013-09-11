<!--- 
 Author: Brandon Purcell
		 support@spatialkey.com
		 
version:
	v1.0 May 21 2009
	v1.1 May 27 2009: 	Changed cookie handling to work on Adbobe CF (worked on Railo before)
						Zip file uploads failed on Adobe CF added workaround with empty form element - added to upload()
	v1.2 June 19 2009:	Added polygon upload feature
	v1.3 Sep 10 2009: 	Added port, protocol and url to login method to make it easier to test outside of the SaaS infrastructe (On-premise install)
						Changed return for all calls to be XML instead of just doing simple CFDUMPs
						Added throwOnFailure argument to login. If the login fails by default we throw a CF error. If set to false then we just return the XML
						The clusterlookup call getCluster() now accepts either the full hostname "myorg.spatialkey.com" or just urlname "myorg"".

This component will allow users to upload data to spatialkey using the Data Publisher API
http://www.spatialkey.com/map/support/documentation/data-import/api/

Usage Example: 
<cfscript>
	objSKdp=createObject('component','SK_DataPublisherAPI');
	objSKdp.login(hostname='skstats.spatialkey.com',username='username',password='pwd');
	
	currDir = GetDirectoryFromPath(GetCurrentTemplatePath());
	xmlFile= currDir & 'SalesData.xml';
	csvFile= currDir & 'SalesData.csv';
	zipFile= currDir & 'SalesData.zip';
	
	/* example uploading both a CSV and XML */ 
	objSKdp.upload(csvfile=csvFile,xmlfile=xmlFile);
	
	/* Example uploading CSV and XML file zipped together */ 
	/* objSKdp.upload(zipfile=zipFile); */
</cfscript>

 --->

<cfcomponent output="false">

	<cfproperty name="jsessionid" type="any" />
	<cfproperty name="clusterURL" type="any" />
	<cfproperty name="protocol" type="any" />
	<cfproperty name="port" type="any" />
	
	<cfscript>
		variables.jsessionid='';
		variables.clusterURL='';
		variables.protocol='';
		variables.port='80';
	</cfscript>

	<cffunction name="getJsessionid" access="public" returntype="string">
		<cfreturn variables.jsessionid />
	</cffunction>
	
	<cffunction name="login" access="public" returntype="xml" output="false">
		<cfargument name="hostname" type="string" required="true" />
		<cfargument name="username" type="string" required="true" />
		<cfargument name="password" type="string" required="true" />
		<cfargument name="doClusterLookup" type="boolean" required="false" default="true" hint="for debugging we can set to false and manually set the protocol, hostname and port">
		<cfargument name="port" type="Numeric" required="false" default="80">
		<cfargument name="protocol" type="String" required="false" default="http://">
		<cfargument name="url" type="String" required="false" default="">
		<cfargument name="throwOnFailure" type="Boolean" required="false" default="true">
		
		<!--- get the cluster information and populate variables.clusterURL, variables.protocol and variables.port --->
		<cfset var objGet=''>
		<cfset var sCookies=''>
		<!--- in the production system we do the lookup --->
		<cfif arguments.doClusterLookup>
			<cfset getCluster(arguments.hostname)>
		<cfelse>
		<!--- for testing --->
			<cfif len(trim(arguments.url)) EQ 0>
				<cfset arguments.url = cgi.server_name>
			</cfif>
			
			<cfset variables.clusterURL=arguments.url>
			<cfset variables.protocol=arguments.protocol>
			<cfset variables.port=arguments.port>
		</cfif>
		
		<cfhttp url="#variables.protocol##variables.clusterURL#:#variables.port#/SpatialKeyFramework/dataImportAPI?action=login&orgName=#replaceNoCase(arguments.hostname,'.spatialkey.com','')#&user=#URLEncodedFormat(arguments.username)#&password=#URLEncodedFormat(arguments.password)#" 
				timeout="90" result="objGet">
		<!--- Check to see if the login completed correctly --->
		<cfif objGet.statuscode EQ '200 OK'>
			<!--- parse the response header cookies --->
			<cfset sCookies=GetResponseCookies(objGet)>
			<cfset variables.jsessionid=sCookies.jsessionid.value>
		<cfelse>
			<cfif arguments.throwOnFailure>
				<cfthrow message="#objGet.fileContent#">
			<cfelse>
				<cfreturn XmlParse(objGet.fileContent)/>
			</cfif>
		</cfif>
		
		<!--- we are ready to upload --->
		<cfreturn XmlParse(objGet.fileContent)/>
	</cffunction>
	
	<cffunction name="renameDataset" access="public" output="false" returntype="xml">
		<cfargument name="name" required="true" type="string">
		<cfargument name="datasetId" required="false" type="string" default="">
		<cfargument name="externalId" required="false" type="string" default="">
		
		<cfif len(trim(arguments.externalId)) EQ 0 AND len(trim(arguments.datasetId)) EQ 0>
			<cfthrow message="Dataset id or external id must be passed to the deleteDataset method.">
		</cfif>
		
		<!--- Call the API --->
		<cfset var methodUrl = "#variables.protocol##variables.clusterURL#:#variables.port#/SpatialKeyFramework/dataImportAPI?action=renameDataset">
		
		<cfif len(trim(arguments.externalId)) GT 0>
			<cfset methodUrl = methodUrl & "&externalId=" & trim(arguments.datasetId)>
		<cfelseif len(trim(arguments.datasetId)) GT 0>
			<cfset methodUrl = methodUrl & "&datasetId=" & trim(arguments.datasetId)>
		</cfif>
		
		<cfset methodUrl = methodUrl & "&name=#URLEncodedFormat(arguments.name)#">
		
		<cfset var objDS = "">
		<cfhttp url="#methodUrl#" timeout="240" result="objDS" >
			<cfhttpparam type="cookie" name="JSESSIONID" value="#variables.jsessionid#">
		</cfhttp>

		<cfreturn XmlParse(objDS.fileContent)/>
	</cffunction>
	
	<cffunction name="deleteDataset" access="public" output="false" returntype="xml">
		<cfargument name="datasetId" required="false" type="string" default="">
		<cfargument name="externalId" required="false" type="string" default="">
		
		<cfif len(trim(arguments.externalId)) EQ 0 AND len(trim(arguments.datasetId)) EQ 0>
			<cfthrow message="Dataset id or external id must be passed to the deleteDataset method.">
		</cfif>
		
		<!--- Call the API --->
		<cfset var methodUrl = "#variables.protocol##variables.clusterURL#:#variables.port#/SpatialKeyFramework/dataImportAPI?action=deleteDataset">
		
		<cfif len(trim(arguments.externalId)) GT 0>
			<cfset methodUrl = methodUrl & "&externalId=" & trim(arguments.datasetId)>
		<cfelseif len(trim(arguments.datasetId)) GT 0>
			<cfset methodUrl = methodUrl & "&datasetId=" & trim(arguments.datasetId)>
		</cfif>
		
		<cfset var objDS = "">
		<cfhttp url="#methodUrl#" timeout="240" result="objDS" >
			<cfhttpparam type="cookie" name="JSESSIONID" value="#variables.jsessionid#">
		</cfhttp>

		<cfreturn XmlParse(objDS.fileContent)/>
	</cffunction>
	
	<cffunction name="getUserDatasets" access="public" output="false" returntype="xml">
		<!--- Call the API --->
		<cfset var methodUrl = "#variables.protocol##variables.clusterURL#:#variables.port#/SpatialKeyFramework/dataImportAPI?action=getUserDatasets">
		
		<cfset var objDS = "">
		<cfhttp url="#methodUrl#" timeout="240" result="objDS" >
			<cfhttpparam type="cookie" name="JSESSIONID" value="#variables.jsessionid#">
		</cfhttp>

		<cfreturn XmlParse(objDS.fileContent)/>
	</cffunction>
	
	<cffunction name="getDatasetInformation" access="public" output="false" returntype="xml" >
		<cfargument name="type" required="false" type="string" default="" >
		<cfargument name="datasetId" required="false" type="string" default="" >
		<cfargument name="externalId" required="false" type="string" default="">
		
		<cfif len(trim(arguments.externalId)) EQ 0 AND len(trim(arguments.type)) EQ 0 AND len(trim(arguments.datasetId)) EQ 0>
			<cfthrow message="Type or dataset id or external id must be passed to the getDatasetInformation method.">
		</cfif>
		
		<!--- Call the API --->
		<cfset var methodUrl = "#variables.protocol##variables.clusterURL#:#variables.port#/SpatialKeyFramework/dataImportAPI?action=getDatasetInformation">
		
		<cfif len(trim(arguments.externalId)) GT 0>
			<cfset methodUrl = methodUrl & "&externalId=" & trim(arguments.datasetId)>
		<cfelseif len(trim(arguments.datasetId)) GT 0>
			<cfset methodUrl = methodUrl & "&datasetId=" & trim(arguments.datasetId)>
		<cfelseif len(trim(arguments.type)) GT 0>
			<cfset methodUrl = methodUrl & "&type=" & trim(arguments.type)>
		</cfif>
		
		<cfhttp url="#methodUrl#" timeout="240" result="objDS" >
			<cfhttpparam type="cookie" name="JSESSIONID" value="#variables.jsessionid#">
		</cfhttp>

		<cfreturn XmlParse(objDS.fileContent)/>
	</cffunction>
	
	<cffunction name="getUserReports" access="public" output="false" returntype="xml">
		<!--- Call the API --->
		<cfset var methodUrl = "#variables.protocol##variables.clusterURL#:#variables.port#/SpatialKeyFramework/dataImportAPI?action=getUserReports">
		
		<cfset var objDS = "">
		<cfhttp url="#methodUrl#" timeout="240" result="objDS" >
			<cfhttpparam type="cookie" name="JSESSIONID" value="#variables.jsessionid#">
		</cfhttp>

		<cfreturn XmlParse(objDS.fileContent)/>
	</cffunction>
	
	<cffunction name="deleteReport" access="public" output="false" returntype="xml">
		<cfargument name="reportId" required="false" type="string" default="">
		
		<!--- Call the API --->
		<cfset var methodUrl = "#variables.protocol##variables.clusterURL#:#variables.port#/SpatialKeyFramework/dataImportAPI?action=deleteReport&reportId=#arguments.reportId#">
		
		<cfset var objDS = "">
		<cfhttp url="#methodUrl#" timeout="240" result="objDS" >
			<cfhttpparam type="cookie" name="JSESSIONID" value="#variables.jsessionid#">
		</cfhttp>

		<cfreturn XmlParse(objDS.fileContent)/>
	</cffunction>
	
	<cffunction name="getOrganizationInformation" access="public" output="false" returntype="xml" >
		<!--- Call the API --->
		<cfset var methodUrl = "#variables.protocol##variables.clusterURL#:#variables.port#/SpatialKeyFramework/dataImportAPI?action=getOrganizationInformation">
		
		<cfhttp url="#methodUrl#" timeout="240" result="objDS" >
			<cfhttpparam type="cookie" name="JSESSIONID" value="#variables.jsessionid#">
		</cfhttp>

		<cfreturn XmlParse(objDS.fileContent)/>
	</cffunction>

	<cffunction name="upload" access="public" output="false" returntype="xml">
		<cfargument name="csvfile" type="string" required="false" default="" />
		<cfargument name="xmlfile" type="string" required="false" default="" />
		<cfargument name="zipfile" type="string" required="false" default="" />
		<cfargument name="action" type="string" required="false" default="overwrite" hint="Action can be overwrite or append">
		<cfargument name="runAsBackGround" type="boolean" required="false" default="false" hint="Run as background should be used for large files ">
		<cfargument name="notifyByEmail" type="boolean" required="false" default="false" hint="Will send an email letting you know when the import is done. Should be used if runAsBackground is true">
		<cfargument name="addAllUsers" type="Boolean" required="false" default="false" hint="Add the AllUsers group as a viewer to the new Dataset?"/>
		<cfargument name="skSampleData" type="Boolean" required="false" default="false">
		<cfargument name="specialDatasetType" type="String" required="false" default="">
		
		<cfset objUpload=''>
		
		<!--- login before upload --->
		<cfif len(variables.jsessionid) EQ 0 OR len(variables.clusterURL) EQ 0 OR len(variables.protocol) EQ 0>
			<cfthrow message="Please call the login() method before calling upload()">
		</cfif>	
		
		<!--- upload the file --->	
		<cfset var methodUrl = "#variables.protocol##variables.clusterURL#:#variables.port#/SpatialKeyFramework/dataImportAPI?action=#arguments.action#&runAsBackground=#arguments.runAsBackGround#&notifyByEmail=#arguments.notifyByEmail#&addAllUsers=#arguments.addAllUsers#">
		
		<cfif skSampleData>
			<cfset methodUrl = methodUrl & "&skSampleData=true">
		</cfif>
		
		<cfif len(trim(specialDatasetType)) GT 0>
			<cfset methodUrl = methodUrl & "&specialDatasetType=" & arguments.specialDatasetType>
		</cfif>
		
		<cfhttp url="#methodUrl#" 
				method="post" timeout="240" result="objUpload" >
			<cfhttpparam type="cookie" name="JSESSIONID" value="#variables.jsessionid#">
			<cfif fileExists(arguments.zipfile)>
				<cfhttpparam type="file" name="zipfile" file="#arguments.zipfile#">
				<!--- Annoying bug in CF so we have to add an extra field to overcome the issue: see http://www.opensubscriber.com/message/cf-talk@houseoffusion.com/9079368.html --->
                <cfhttpparam type="formfield" name="bugworkaround" value=""/>
			<cfelse>
				<cfhttpparam type="file" name="xmlfile" file="#arguments.xmlfile#">
				<cfhttpparam type="file" name="csvfile" file="#arguments.csvfile#">
			</cfif>
		</cfhttp>

		<cfreturn XmlParse(objUpload.fileContent)/>
	</cffunction>
	
	<cffunction name="deleteDataByRange" access="public" output="false" returntype="xml">
		<cfargument name="column" type="string" required="true">
		<cfargument name="startRange" type="string" required="true">
		<cfargument name="endRange" type="string" required="true">
		<cfargument name="dataType" type="string" required="false" default="date">
		<cfargument name="xmlfile" type="string" required="false" default="" />
		<cfargument name="zipfile" type="string" required="false" default="" />
		
		<cfset objUpload=''>
		
		<!--- login before upload --->
		<cfif len(variables.jsessionid) EQ 0 OR len(variables.clusterURL) EQ 0 OR len(variables.protocol) EQ 0>
			<cfthrow message="Please call the login() method before calling deleteDataByRange()">
		</cfif>	
		
		<!--- upload the file --->	
		<cfset var methodUrl = "#variables.protocol##variables.clusterURL#:#variables.port#/SpatialKeyFramework/dataImportAPI?action=deleteDataByRange&column=#arguments.column#&startRange=#arguments.startRange#&endRange=#arguments.endRange#&dataType=#arguments.dataType#">
		
		<cfhttp url="#methodUrl#" 
				method="post" timeout="240" result="objUpload" >
			<cfhttpparam type="cookie" name="JSESSIONID" value="#variables.jsessionid#">
			<cfif fileExists(arguments.zipfile)>
				<cfhttpparam type="file" name="zipfile" file="#arguments.zipfile#">
				<!--- Annoying bug in CF so we have to add an extra field to overcome the issue: see http://www.opensubscriber.com/message/cf-talk@houseoffusion.com/9079368.html --->
                <cfhttpparam type="formfield" name="bugworkaround" value=""/>
			<cfelse>
				<cfhttpparam type="file" name="xmlfile" file="#arguments.xmlfile#">
			</cfif>
		</cfhttp>

		<cfreturn XmlParse(objUpload.fileContent)/>
	</cffunction>

	<cffunction name="getCluster" access="private" output="false" hint="sets the cluster that the data import will call based on the hostname of the On-Demand instance">
		<cfargument name="hostname" type="string" required="true" />
		<cfset var XMLContent=''>
		<cfset var objGet=''>
		
		<!--- we should make this work if either brandon or brandon.spatialkey.com is passed in
		by default we are expecting the full hostname: brandon.spatialkey.com
		 --->
		 <cfif NOT findNoCase('.spatialkey.com',arguments.hostname)>
		 	<cfset arguments.hostname=arguments.hostname & '.spatialkey.com'>
		 </cfif>
		
		<!--- Call to get the cluster URL and protocol --->
		<cfhttp url="http://#arguments.hostname#/clusterlookup.cfm" timeout="20" result="objGet">
		<cfset XMLContent=XMLParse(trim(objGet.filecontent))>
		
	    <cfif Len(XMLContent.organization.error.XMLText) GT 0><!--- there was an error --->
			<cfthrow message="There was an error with #arguments.hostname#: #XMLContent.organization.error.XMLText#">
		<cfelse>
			<cfscript>
				variables.clusterURL=XMLContent.organization.cluster.XMLText;
				variables.protocol=XMLContent.organization.protocol.XMLText;
				variables.organizationID=XMLContent.organization.organizationID.XMLText;
				if (variables.protocol EQ 'https://'){
					variables.port=443;
				}
			</cfscript>
		</cfif>
		<cfreturn />
	</cffunction>
	
	<cffunction name="uploadPolygons" access="public" output="true" returntype="Any">
		<cfargument name="file" type="string" required="true" default="" />
		<cfargument name="datasetName" type="string" required="false" default="" />
		<cfargument name="datasetId" type="string" required="false" default="" />
		<cfargument name="addAllUsers" displayname="Add the All Users group?" type="string" required="false" default="false">
		<cfset var objUpload=''>
		
		<!--- login before upload --->
		<cfif len(variables.jsessionid) EQ 0 OR len(variables.clusterURL) EQ 0 OR len(variables.protocol) EQ 0>
			<cfthrow message="Please call the login() method before calling upload()">
		</cfif>	
		
		<cfif len(trim(arguments.datasetName)) EQ 0 AND len(trim(arguments.datasetId)) EQ 0>
		
			<cfthrow message="You must pass either a dataset name or id to the upload method.">
		</cfif>
		
		<!--- upload the file --->	
		<cfif len(trim(arguments.datasetName))>
			<cfhttp url="#variables.protocol##variables.clusterURL#:#variables.port#/SpatialKeyFramework/dataImportAPI?action=poly&datasetName=#URLEncodedFormat(arguments.datasetName)#&addAllUsers=#arguments.addAllUsers#" 
					method="post" timeout="240" result="objUpload" >
				<cfhttpparam type="cookie" name="JSESSIONID" value="#variables.jsessionid#">
				<cfhttpparam type="file" name="file" file="#arguments.file#">
				<!--- Annoying bug in CF so we have to add an extra field to overcome the issue: see http://www.opensubscriber.com/message/cf-talk@houseoffusion.com/9079368.html --->
	            <cfhttpparam type="formfield" name="bugworkaround" value=""/>
			</cfhttp>
		<cfelse>
			<cfhttp url="#variables.protocol##variables.clusterURL#:#variables.port#/SpatialKeyFramework/dataImportAPI?action=poly&datasetId=#URLEncodedFormat(arguments.datasetId)#" 
					method="post" timeout="240" result="objUpload" >
				<cfhttpparam type="cookie" name="JSESSIONID" value="#variables.jsessionid#">
				<cfhttpparam type="file" name="file" file="#arguments.file#">
				<!--- Annoying bug in CF so we have to add an extra field to overcome the issue: see http://www.opensubscriber.com/message/cf-talk@houseoffusion.com/9079368.html --->
	            <cfhttpparam type="formfield" name="bugworkaround" value=""/>
			</cfhttp>
		</cfif>
		
		<cfreturn XmlParse(objUpload.fileContent)/>
	</cffunction>
	
	
	<!--- GetResponseCookies is from Ben Nadel - http://www.bennadel.com/index.cfm?dax=blog:725.view --->
	    <cffunction name="GetResponseCookies" access="public"  returntype="struct"
	     output="false"
	     hint="This parses the response of a CFHttp call and puts the cookies into a struct.">
	      
	     <!--- Define arguments. --->
	     <cfargument name="Response" type="struct" required="true" hint="The response of a CFHttp call."/>
	      
	     <!--- Define the local scope. --->
	     <cfset var LOCAL = StructNew() />
	      
	     <cfset LOCAL.Cookies = StructNew() />
	      
	  
	     <cfif NOT StructKeyExists(ARGUMENTS.Response.ResponseHeader,"Set-Cookie")>
	       <!--- No cookies were send back in the response. Just return the empty cookies structure.--->
	     	<cfreturn LOCAL.Cookies />
	     </cfif>
	      
	     <!---
	     Now that we know that the cookies were returned, get
	     a reference to the struct as described above.
	     --->
	     <cfset LOCAL.ReturnedCookies = ARGUMENTS.Response.ResponseHeader[ "Set-Cookie" ] />
	      
	      
	     <!--- Loop over the returned cookies struct. --->
	     <cfloop item="LOCAL.CookieIndex" collection="#LOCAL.ReturnedCookies#">
	      
	      
	     <!--- As we loop through the cookie struct, get the cookie string we want to parse.  --->
	     <cfset LOCAL.CookieString = LOCAL.ReturnedCookies[ LOCAL.CookieIndex ] />
	      
	      
		     <!--- For each of these cookie strings, we are going to need to parse out the values. We can treate the cookie string as a semi-colon delimited list. --->
		     <cfloop index="LOCAL.Index" from="1" to="#ListLen( LOCAL.CookieString, ';' )#" step="1">
		      
		     <!--- Get the name-value pair. --->
		     <cfset LOCAL.Pair = ListGetAt(LOCAL.CookieString,LOCAL.Index,";") />
		      
		      
		     <!--- Get the name as the first part of the pair sepparated by the equals sign.--->
		     <cfset LOCAL.Name = ListFirst( LOCAL.Pair, "=" ) />
		      
		     <!---Check to see if we have a value part. Not allcookies are going to send values of length,which can throw off ColdFusion.--->
		     <cfif (ListLen( LOCAL.Pair, "=" ) GT 1)>
			     <!--- Grab the rest of the list. --->
			     <cfset LOCAL.Value = ListRest( LOCAL.Pair, "=" ) />
		     <cfelse> 
			     <!---Since ColdFusion did not find more than one value in the list, just get the empty string as the value.--->
			     <cfset LOCAL.Value = "" />
		     </cfif>
		      
		      
		     <!--- Now that we have the name-value data values,we have to store them in the struct. If we are looking at the first part of the cookie string,
		     this is going to be the name of the cookie and it's struct index. --->
		     <cfif (LOCAL.Index EQ 1)>
		      
			     <!---Create a new struct with this cookie's name as the key in the return cookie struct. --->
			     <cfset LOCAL.Cookies[ LOCAL.Name ] = StructNew() />
			      
			     <!--- Now that we have the struct in place, letsget a reference to it so that we can referto it in subseqent loops. --->
			     <cfset LOCAL.Cookie = LOCAL.Cookies[ LOCAL.Name ] />
			      
			     <!--- Store the value of this cookie. --->
			     <cfset LOCAL.Cookie.Value = LOCAL.Value />
			      
			     <!--- Now, this cookie might have more than justthe first name-value pair. Let's create anadditional attributes struct to hold thosevalues.--->
			     <cfset LOCAL.Cookie.Attributes = StructNew() />
			      
		     <cfelse>
			     <!---For all subseqent calls, just store thename-value pair into the established cookie's attributes strcut.--->
	
		     </cfif>
		      
		     </cfloop>

	     </cfloop>

	     <!--- Return the cookies. --->
	     <cfreturn LOCAL.Cookies />
     </cffunction>
</cfcomponent>