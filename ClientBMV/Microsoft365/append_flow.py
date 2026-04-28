content = """\
        </text>
    </textTemplates>

    <!-- ELEMENT 1: Get At Risk Opportunities -->
    <recordLookups>
        <name>Get_At_Risk_Opportunities</name>
        <label>Get At Risk Opportunities</label>
        <locationX>176</locationX>
        <locationY>134</locationY>
        <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
        <connector>
            <targetReference>Loop_Opportunities</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>IsClosed</field>
            <operator>EqualTo</operator>
            <value>
                <booleanValue>false</booleanValue>
            </value>
        </filters>
        <filters>
            <field>Days_No_Activity__c</field>
            <operator>GreaterThanOrEqualTo</operator>
            <value>
                <numberValue>7.0</numberValue>
            </value>
        </filters>
        <object>Opportunity</object>
        <outputReference>varAtRiskOpportunities</outputReference>
        <queriedFields>Id</queriedFields>
        <queriedFields>Name</queriedFields>
        <queriedFields>StageName</queriedFields>
        <queriedFields>CloseDate</queriedFields>
        <queriedFields>OwnerId</queriedFields>
        <queriedFields>Days_No_Activity__c</queriedFields>
        <queriedFields>Investor_Type__c</queriedFields>
        <queriedFields>AUM_Range__c</queriedFields>
        <sortField>Days_No_Activity__c</sortField>
        <sortOrder>Desc</sortOrder>
    </recordLookups>

    <!-- ELEMENT 2: Loop At Risk Opportunities -->
    <loops>
        <name>Loop_Opportunities</name>
        <label>Loop At Risk Opportunities</label>
        <locationX>176</locationX>
        <locationY>254</locationY>
        <collectionReference>varAtRiskOpportunities</collectionReference>
        <iterationOrder>Asc</iterationOrder>
        <nextValueConnector>
            <targetReference>Get_Owner</targetReference>
        </nextValueConnector>
        <outputReference>varCurrentOpportunity</outputReference>
    </loops>

    <!-- ELEMENT 3: Get Opportunity Owner -->
    <recordLookups>
        <name>Get_Owner</name>
        <label>Get Opportunity Owner</label>
        <locationX>176</locationX>
        <locationY>374</locationY>
        <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
        <connector>
            <targetReference>Run_Risk_Prompt</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Id</field>
            <operator>EqualTo</operator>
            <value>
                <elementReference>varCurrentOpportunity.OwnerId</elementReference>
            </value>
        </filters>
        <getFirstRecordOnly>true</getFirstRecordOnly>
        <object>User</object>
        <outputReference>varOwner</outputReference>
        <queriedFields>Id</queriedFields>
        <queriedFields>Name</queriedFields>
        <queriedFields>Email</queriedFields>
        <queriedFields>Teams_UPN__c</queriedFields>
    </recordLookups>

    <!-- ELEMENT 4: Run Risk Analysis Prompt (Einstein Prompt Template) -->
    <actionCalls>
        <name>Run_Risk_Prompt</name>
        <label>Run Risk Analysis Prompt</label>
        <locationX>176</locationX>
        <locationY>494</locationY>
        <actionName>BMV_Opportunity_Risk_Analysis</actionName>
        <actionType>generateFlexiblePrompt</actionType>
        <connector>
            <targetReference>Parse_Risk_Response</targetReference>
        </connector>
        <inputParameters>
            <name>Input:recordId</name>
            <value>
                <elementReference>varCurrentOpportunity.Id</elementReference>
            </value>
        </inputParameters>
        <outputParameters>
            <assignToReference>varRawRiskResponse</assignToReference>
            <name>Output</name>
        </outputParameters>
    </actionCalls>

    <!-- ELEMENT 5: Parse Risk Response (Apex Action) -->
    <actionCalls>
        <name>Parse_Risk_Response</name>
        <label>Parse Risk Response</label>
        <locationX>176</locationX>
        <locationY>614</locationY>
        <actionName>BMVOpptyRiskParser</actionName>
        <actionType>apex</actionType>
        <connector>
            <targetReference>Check_Risk_Level</targetReference>
        </connector>
        <inputParameters>
            <name>rawResponse</name>
            <value>
                <elementReference>varRawRiskResponse</elementReference>
            </value>
        </inputParameters>
        <outputParameters>
            <assignToReference>varRiskLevel</assignToReference>
            <name>riskLevel</name>
        </outputParameters>
        <outputParameters>
            <assignToReference>varRiskReason</assignToReference>
            <name>riskReason</name>
        </outputParameters>
        <outputParameters>
            <assignToReference>varNextAction</assignToReference>
            <name>nextAction</name>
        </outputParameters>
        <outputParameters>
            <assignToReference>varUrgency</assignToReference>
            <name>urgency</name>
        </outputParameters>
        <outputParameters>
            <assignToReference>varPersonalMessage</assignToReference>
            <name>personalMessage</name>
        </outputParameters>
    </actionCalls>

    <!-- ELEMENT 6: Check Risk Level (Decision) -->
    <decisions>
        <name>Check_Risk_Level</name>
        <label>Check Risk Level</label>
        <locationX>176</locationX>
        <locationY>734</locationY>
        <defaultConnector>
            <isGoTo>true</isGoTo>
            <targetReference>Loop_Opportunities</targetReference>
        </defaultConnector>
        <defaultConnectorLabel>Medium Or Low</defaultConnectorLabel>
        <rules>
            <name>High_Or_Critical</name>
            <conditionLogic>or</conditionLogic>
            <conditions>
                <leftValueReference>varRiskLevel</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue>
                    <stringValue>High</stringValue>
                </rightValue>
            </conditions>
            <conditions>
                <leftValueReference>varRiskLevel</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue>
                    <stringValue>Critical</stringValue>
                </rightValue>
            </conditions>
            <connector>
                <targetReference>Set_Risk_Flag</targetReference>
            </connector>
            <label>High Or Critical</label>
        </rules>
    </decisions>

    <!-- ELEMENT 7: Set Risk Flag on Opportunity -->
    <recordUpdates>
        <name>Set_Risk_Flag</name>
        <label>Set Risk Flag on Opportunity</label>
        <locationX>44</locationX>
        <locationY>854</locationY>
        <connector>
            <targetReference>Send_To_Power_Automate</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Id</field>
            <operator>EqualTo</operator>
            <value>
                <elementReference>varCurrentOpportunity.Id</elementReference>
            </value>
        </filters>
        <inputAssignments>
            <field>Risk_Flag__c</field>
            <value>
                <booleanValue>true</booleanValue>
            </value>
        </inputAssignments>
        <object>Opportunity</object>
    </recordUpdates>

    <!-- ELEMENT 8: Send Risk Alert to Power Automate (HTTP Callout) -->
    <actionCalls>
        <name>Send_To_Power_Automate</name>
        <label>Send Risk Alert to Power Automate</label>
        <locationX>44</locationX>
        <locationY>974</locationY>
        <actionName>Power_Automate_Risk_Alert</actionName>
        <actionType>httpCallout</actionType>
        <connector>
            <isGoTo>true</isGoTo>
            <targetReference>Loop_Opportunities</targetReference>
        </connector>
        <inputParameters>
            <name>method</name>
            <value>
                <stringValue>POST</stringValue>
            </value>
        </inputParameters>
        <inputParameters>
            <name>path</name>
            <value>
                <stringValue>/powerautomate/automations/direct/workflows/14a199ead048416fa871014bb9d31b27/triggers/manual/paths/invoke?api-version=1</stringValue>
            </value>
        </inputParameters>
        <inputParameters>
            <name>headers</name>
            <value>
                <stringValue>[{"key":"Content-Type","value":"application/json"}]</stringValue>
            </value>
        </inputParameters>
        <inputParameters>
            <name>body</name>
            <value>
                <elementReference>tmplRequestBody</elementReference>
            </value>
        </inputParameters>
    </actionCalls>

</Flow>
"""

path = r"c:/Users/Raveendhran/Desktop/Microsoft 365/Microsoft365/force-app/main/default/flows/BMV_Opportunity_Risk_Alert_Scheduled.flow-meta.xml"
with open(path, "a", encoding="utf-8") as f:
    f.write(content)
print("Done - appended successfully")
