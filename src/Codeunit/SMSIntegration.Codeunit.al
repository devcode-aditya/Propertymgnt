codeunit 33016804 "SMS Integration"
{
    // DP = changes made by DVS


    trigger OnRun()
    var
        locautXmlDoc: Automation BC;
        locautXmlHttp: Automation BC;
        locautSoapHttpConnector: Automation BC;
        locautSoapSerializer: Automation BC;
    begin
        IF ReceiverMobileNo <> '' THEN BEGIN
            SMSIntegrationSetup.GET;
            SMSIntegrationSetup.TESTFIELD("Mobile No. Digits Allowed");
            IF STRLEN(ReceiverMobileNo) <> SMSIntegrationSetup."Mobile No. Digits Allowed" THEN
                ERROR(Text001, SMSIntegrationSetup."Mobile No. Digits Allowed");
            SMSIntegrationSetup.TESTFIELD("SMS HTTP URL");
            SMSIntegrationSetup.TESTFIELD("SMS User");
            SMSIntegrationSetup.TESTFIELD("SMS Password");
            SMSIntegrationSetup.TESTFIELD("SMS Sender Phone");
            SMSIntegrationSetup.TESTFIELD("SOAP Action");

            CREATE(locautSoapHttpConnector);
            locautSoapHttpConnector.Property('EndPointURL', SMSIntegrationSetup."SMS HTTP URL");
            locautSoapHttpConnector.Connect;
            locautSoapHttpConnector.Property('SoapAction', SMSIntegrationSetup."SOAP Action");
            locautSoapHttpConnector.BeginMessage;
            CREATE(locautSoapSerializer);
            locautSoapSerializer.Init(locautSoapHttpConnector.InputStream);
            locautSoapSerializer.StartEnvelope('', 'STANDARD', 'utf-8');
            locautSoapSerializer.StartBody('STANDARD');
            locautSoapSerializer.StartElement('SendTextSMS', 'SMSCountry WebService');

            locautSoapSerializer.StartElement('username', 'SMSCountry WebService');
            locautSoapSerializer.WriteString(SMSIntegrationSetup."SMS User");
            locautSoapSerializer.EndElement;

            locautSoapSerializer.StartElement('password', 'SMSCountry WebService');
            locautSoapSerializer.WriteString(SMSIntegrationSetup."SMS Password");
            locautSoapSerializer.EndElement;

            locautSoapSerializer.StartElement('mobilenumbers', 'SMSCountry WebService');
            locautSoapSerializer.WriteString(ReceiverMobileNo);
            locautSoapSerializer.EndElement;

            locautSoapSerializer.StartElement('message', 'SMSCountry WebService');
            locautSoapSerializer.WriteString(SMSIntegrationSetup."Header Text" + '  ' + ReceiverDescription + '  ' +
            SMSIntegrationSetup."Footnote Text");
            locautSoapSerializer.EndElement;

            locautSoapSerializer.StartElement('senderID', 'SMSCountry WebService');
            locautSoapSerializer.WriteString(SMSIntegrationSetup."SMS Sender Phone");
            locautSoapSerializer.EndElement;

            locautSoapSerializer.EndElement;
            locautSoapSerializer.EndBody;
            locautSoapSerializer.EndEnvelope;
            locautSoapHttpConnector.EndMessage;

            CREATE(locautXmlHttp);
            CREATE(locautXmlDoc);
            locautXmlDoc.async := FALSE;
            locautXmlDoc.load(locautSoapHttpConnector.OutputStream);

            filepath := SMSIntegrationSetup."Sent SMS File Path" + '\SMS-' + ReceiverName + '-' + ReceiverMobileNo + '-' +
            FORMAT(TODAY, 0, '<day,2>-<month,2>-<year4>') + FORMAT(TIME, 0, '<hours24><minutes,2><seconds,2>') + '.xml';

            locautXmlDoc.save(filepath);
            locautXmlHttp.open('POST', SMSIntegrationSetup."SMS HTTP URL", FALSE);
            locautXmlHttp.setRequestHeader('Content-Type: ', 'application/soap+xml; charset="UTF-8"');
            locautXmlHttp.setRequestHeader('SOAPAction', SMSIntegrationSetup."SOAP Action");
            locautXmlHttp.send(locautXmlDoc);
            locautXmlDoc.load(locautXmlHttp.responseXML);

            ResponseFilePath := SMSIntegrationSetup."Response File Path" + '\Response-' + ReceiverName + '-' + ReceiverMobileNo + '-' +
            FORMAT(TODAY, 0, '<day,2>-<month,2>-<year4>') + FORMAT(TIME, 0, '<hours24><minutes,2><seconds,2>') + '.xml';

            CLEAR(locautXmlDoc);
            CREATE(locautXmlDoc);
            locautXmlDoc.load(locautSoapHttpConnector.OutputStream);
            locautXmlDoc.save(ResponseFilePath);
        END;
    end;

    var
        SMSIntegrationSetup: Record "SMS Integration Setup";
        ReceiverMobileNo: Text[30];
        ReceiverDescription: Text[256];
        filepath: Text[1000];
        ResponseFilePath: Text[1000];
        Text001: Label 'Mobile No. must be of exact %1 digits';
        ReceiverName: Text[100];

    procedure SetMobileNo(RevMobileNo: Text[30])
    begin
        ReceiverMobileNo := RevMobileNo;
    end;

    procedure SetDescription(RevDescription: Text[256])
    begin
        ReceiverDescription := RevDescription;
    end;

    procedure SetReceiverName(NameofReceiver: Text[100])
    begin
        ReceiverName := NameofReceiver;
    end;
}

