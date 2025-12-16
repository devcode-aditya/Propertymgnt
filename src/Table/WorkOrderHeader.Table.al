table 33016822 "Work Order Header"
{
    Caption = 'Work Order Header';
    LookupFormID = Form33016837;

    fields
    {
        field(1; "Document Type"; Option)
        {
            OptionCaption = 'Work Order';
            OptionMembers = "Work Order";
        }
        field(2; "No."; Code[20])
        {

            trigger OnValidate()
            begin
                IF "No." <> xRec."No." THEN BEGIN
                    PremiseMgt.GET;
                    NoSeriesMgt.TestManual(PremiseMgt."Work Order");
                    "No. Series" := '';
                END;
            end;
        }
        field(3; "Request From"; Option)
        {
            OptionCaption = 'Premise,Facility';
            OptionMembers = Premise,Facility;

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF "Request From" <> xRec."Request From" THEN BEGIN
                    VALIDATE("Premise/Facility No.", '');
                    VALIDATE("Contact No.", '');
                END;
            end;
        }
        field(4; "Premise/Facility No."; Code[20])
        {
            TableRelation = IF (Request From=FILTER(Premise)) Premise.No. WHERE (Blocked=FILTER(No))
                            ELSE IF (Request From=FILTER(Facility)) Facility.No.;

            trigger OnValidate()
            var
                PremiseRec: Record Premise;
                FacilityRec: Record Facility;
            begin
                TestStatusOpen;
                IF "Premise/Facility No." <> xRec."Premise/Facility No." THEN BEGIN
                  "Contact No." := '';
                  "Contact Method" := 0;
                  "Contact Name" := '';
                  "Call Back No." := '';
                  "Client No." := '';
                END;

                CASE "Request From" OF
                  "Request From"::Premise:
                  BEGIN
                    IF "Premise/Facility No." <> '' THEN BEGIN
                      PremiseRec.GET("Premise/Facility No.");
                      PremiseRec.TESTFIELD(Blocked,FALSE);
                      Name := PremiseRec.Name;
                      "Premise/Sub Premise" := PremiseRec."Premise/Sub-Premise";
                      City := PremiseRec.City;
                      "Shortcut Dimension 1 Code" := PremiseRec."Global Dimension 1 Code";
                      "Shortcut Dimension 2 Code" := PremiseRec."Global Dimension 2 Code";
                      "Client No." := PremiseRec."Client No.";
                      "Floor No." := PremiseRec."Floor No.";
                    END ELSE BEGIN
                      Name := '';
                      "Premise/Sub Premise" := 0;
                      City := '';
                      "Shortcut Dimension 1 Code" := '';
                      "Shortcut Dimension 2 Code" := '';
                      "Client No." := '';
                      "Subunit No." := '';
                      "Floor No." := '';
                    END;
                  END;

                  "Request From"::Facility:
                  BEGIN
                    IF "Premise/Facility No." <> '' THEN BEGIN
                      FacilityRec.GET("Premise/Facility No.");
                      Name := FacilityRec.Name;
                      "Shortcut Dimension 1 Code" := FacilityRec."Global Dimension 1 Code";
                      "Shortcut Dimension 2 Code" := FacilityRec."Global Dimension 2 Code";
                      IF PremiseRec.GET(FacilityRec."Linked Premise Code") THEN BEGIN
                        "Premise/Sub Premise" := PremiseRec."Premise/Sub-Premise";
                        City := PremiseRec.City;
                        "Client No." := PremiseRec."Client No.";
                      END ELSE BEGIN
                        "Premise/Sub Premise" := 0;
                        City := '';
                        "Client No." := '';
                      END;
                    END ELSE BEGIN
                      Name := '';
                      "Shortcut Dimension 1 Code" := '';
                      "Shortcut Dimension 2 Code" := '';
                      "Premise/Sub Premise" := 0;
                      City := '';
                      "Client No." := '';
                    END;
                    "Subunit No." := '';
                  END;
                END;
            end;
        }
        field(5;"Premise/Sub Premise";Option)
        {
            Editable = false;
            OptionCaption = 'Premise,Sub-Premise';
            OptionMembers = Premise,"Sub-Premise";
        }
        field(6;"Subunit No.";Code[20])
        {
            TableRelation = IF (Request From=FILTER(Premise)) "Premise Subunit".Code WHERE (Premise Code=FIELD(Premise/Facility No.));

            trigger OnValidate()
            var
                PremiseSubunitRec: Record "Premise Subunit";
            begin
                TestStatusOpen;
                IF "Request From" = "Request From"::Premise THEN BEGIN
                  IF "Subunit No." <> '' THEN BEGIN
                    IF PremiseSubunitRec.GET("Premise/Facility No.","Subunit No.") THEN
                      "Subunit Description" := PremiseSubunitRec.Code
                    ELSE
                     "Subunit Description" := '';
                  END ELSE
                    "Subunit Description" := '';
                END ELSE
                  "Subunit Description" := '';
            end;
        }
        field(7;"Floor No.";Code[10])
        {
            TableRelation = "Premise Floor"."Floor No.";
        }
        field(8;"Contact No.";Code[20])
        {

            trigger OnLookup()
            var
                PremiseContactRec: Record "Premise Contact";
                FacilityContactRec: Record "Facility Contact";
                PremiseContactFrm: Form "33016833";
                FacilityContactFrm: Form "33016876";
            begin
                CASE "Request From" OF
                  "Request From"::Premise:
                    BEGIN
                      PremiseContactRec.RESET;
                      CLEAR(PremiseContactFrm);
                      PremiseContactRec.SETRANGE("Premise Code","Premise/Facility No.");
                      PremiseContactFrm.SETTABLEVIEW(PremiseContactRec);
                      PremiseContactFrm.SETRECORD(PremiseContactRec);
                      //PremiseContactFrm.EDITABLE(FALSE);
                      PremiseContactFrm.LOOKUPMODE(TRUE);
                      IF PremiseContactFrm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                        PremiseContactFrm.GETRECORD(PremiseContactRec);
                        VALIDATE("Contact No.",PremiseContactRec."No.");
                      END;
                    END;
                  "Request From"::Facility:
                    BEGIN
                      FacilityContactRec.RESET;
                      CLEAR(FacilityContactFrm);
                      FacilityContactRec.SETRANGE("Facility Code","Premise/Facility No.");
                      FacilityContactFrm.SETTABLEVIEW(FacilityContactRec);
                      FacilityContactFrm.SETRECORD(FacilityContactRec);
                      //FacilityContactFrm.EDITABLE(FALSE);
                      FacilityContactFrm.LOOKUPMODE(TRUE);
                      IF FacilityContactFrm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                        FacilityContactFrm.GETRECORD(FacilityContactRec);
                        VALIDATE("Contact No.",FacilityContactRec."No.");
                      END;
                    END;
                END;
            end;

            trigger OnValidate()
            var
                PremiseContactRec: Record "Premise Contact";
                FacilityContactRec: Record "Facility Contact";
            begin
                CASE "Request From" OF
                  "Request From"::Premise:
                  BEGIN
                    IF "Contact No." <> '' THEN BEGIN
                      TESTFIELD("No.");
                      IF PremiseContactRec.GET("Premise/Facility No.","Contact No.") THEN BEGIN
                        "Contact Method" := PremiseContactRec."Contact Method";
                        "Contact Name" := PremiseContactRec.Name;
                        "Call Back No." := PremiseContactRec."Phone No.";
                      END ELSE BEGIN
                        "Contact No." := '';
                        "Contact Method" := 0;
                        "Contact Name" := '';
                        "Call Back No." := '';
                      END;
                    END ELSE BEGIN
                      "Contact Method" := 0;
                      "Contact Name" := '';
                      "Call Back No." := '';
                    END;
                  END;
                  "Request From"::Facility:
                  BEGIN
                    IF "Contact No." <> '' THEN BEGIN
                      TESTFIELD("No.");
                      IF FacilityContactRec.GET("Premise/Facility No.","Contact No.") THEN BEGIN
                        "Contact Method" := FacilityContactRec."Contact Method";
                        "Contact Name" := FacilityContactRec.Name;
                        "Call Back No." := FacilityContactRec."Phone No.";
                      END ELSE BEGIN
                        "Contact No." := '';
                        "Contact Method" := 0;
                        "Contact Name" := '';
                        "Call Back No." := '';
                      END;
                    END ELSE BEGIN
                      "Contact Method" := 0;
                      "Contact Name" := '';
                      "Call Back No." := '';
                    END;
                  END;
                END;
            end;
        }
        field(9;"Call Back No.";Text[30])
        {
        }
        field(10;"Contact Method";Option)
        {
            OptionCaption = 'Phone,E-mail,Fax,In Person';
            OptionMembers = Phone,"E-mail",Fax,"In Person";
        }
        field(11;Description;Text[80])
        {
            Caption = 'Work Order Description';
        }
        field(12;"Priority Code";Code[10])
        {
            TableRelation = "Work Priority".Code;

            trigger OnValidate()
            var
                WorkPriorityRec: Record "Work Priority";
            begin
                IF "Priority Code" <> '' THEN BEGIN
                  WorkPriorityRec.GET("Priority Code");
                  "Priorty Description" := WorkPriorityRec.Description;
                END ELSE
                  "Priorty Description" := '';
            end;
        }
        field(13;"WO Status";Option)
        {
            Editable = false;
            OptionCaption = 'New,Active,Cancelled,Closed';
            OptionMembers = New,Active,Cancelled,Closed;

            trigger OnValidate()
            var
                CompletionCodeRec: Record "Completion Code";
                MaintCalendarLine: Record "Maintenance Calendar";
            begin
                IF "WO Status" <> xRec."WO Status" THEN BEGIN
                  IF "WO Status" = "WO Status"::Active THEN
                    TESTFIELD("Approval Status","Approval Status"::Released);
                  IF "WO Status" = "WO Status"::Closed THEN BEGIN
                    IF xRec."WO Status" = xRec."WO Status"::New THEN
                      ERROR(Text005);
                    TESTFIELD("Helpdesk Feedback");
                    TESTFIELD("Maintenance Staff Feedback");
                    TESTFIELD("Completion Date");
                    TESTFIELD("Completion Code");
                    Closed := TRUE;
                    MaintCalendarLine.SETRANGE("Work Order No.","No.");
                    IF MaintCalendarLine.FINDSET THEN BEGIN
                      REPEAT
                        MaintCalendarLine."WO Closed/Cancelled" := TRUE;
                        MaintCalendarLine.MODIFY;
                      UNTIL MaintCalendarLine.NEXT = 0;
                    END;
                  END;
                  IF "WO Status" = "WO Status"::Cancelled THEN BEGIN
                    IF CONFIRM(Text007,FALSE) THEN BEGIN
                      DeleteAllocationEntries;
                      Closed := TRUE;
                      MaintCalendarLine.SETRANGE("Work Order No.","No.");
                      IF MaintCalendarLine.FINDSET THEN BEGIN
                        REPEAT
                          MaintCalendarLine."WO Closed/Cancelled" := TRUE;
                          MaintCalendarLine.MODIFY;
                        UNTIL MaintCalendarLine.NEXT = 0;
                      END;
                    END ELSE
                      ERROR('');
                  END;
                END;
            end;
        }
        field(14;"Date Created";Date)
        {
            Editable = false;
        }
        field(15;"Time Created";Time)
        {
            Editable = false;
        }
        field(16;"User ID";Code[20])
        {
            Editable = false;
            TableRelation = User;
        }
        field(17;"Last DateTime Modified";DateTime)
        {
            Editable = false;
        }
        field(18;"Last User Modified";Code[20])
        {
            Editable = false;
        }
        field(19;Name;Text[50])
        {
            Editable = false;
        }
        field(20;City;Text[30])
        {
            Editable = false;
        }
        field(21;"Subunit Description";Text[30])
        {
            Editable = false;
        }
        field(22;"Contact Name";Text[50])
        {
        }
        field(23;"Priorty Description";Text[30])
        {
            Editable = false;
        }
        field(25;"Converted From";Code[20])
        {
            Editable = false;
            TableRelation = "Call Register".No.;
        }
        field(26;"Conversion Date Time";DateTime)
        {
            Editable = false;
        }
        field(27;"Document Date";Date)
        {
        }
        field(28;"Complaint Code";Code[10])
        {
            TableRelation = "Complaint Type".Code;

            trigger OnValidate()
            var
                ComplaintRec: Record "Complaint Type";
            begin
                IF "Complaint Code" <> '' THEN BEGIN
                  ComplaintRec.GET("Complaint Code");
                  "Complaint Description" := ComplaintRec.Description;
                  VALIDATE("Job Type",ComplaintRec."Job Type");
                END ELSE BEGIN
                  "Complaint Description" := '';
                  IF ("Job Type" <> '') AND (xRec."Complaint Code" <> '') AND ComplaintRec.GET(xRec."Complaint Code") THEN
                    IF (ComplaintRec."Job Type")  = ("Job Type") THEN
                      VALIDATE("Job Type",'');
                END;
            end;
        }
        field(29;"Job Type";Code[20])
        {
            TableRelation = "Job Type".Code;

            trigger OnValidate()
            var
                JobTypeRec: Record "Job Type";
            begin
                IF "Job Type" <> '' THEN BEGIN
                  JobTypeRec.GET("Job Type");
                  "Job Description" := JobTypeRec.Description;
                END ELSE
                  "Job Description" := '';
            end;
        }
        field(30;"Complaint Description";Text[30])
        {
            Editable = false;
        }
        field(31;"Job Description";Text[50])
        {
            Editable = false;
        }
        field(32;"Resource Type";Option)
        {
            OptionCaption = 'Internal,External';
            OptionMembers = Internal,External;
        }
        field(33;"No. of Resources";Integer)
        {
            BlankZero = true;
            CalcFormula = Count("WO Res. Allocation" WHERE (Work Order No.=FIELD(No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(35;"Assigned Date";Date)
        {
        }
        field(36;"Assigned Time";Time)
        {
        }
        field(37;"Start Date";Date)
        {
        }
        field(38;"Start Time";Time)
        {
        }
        field(39;"Due Date";Date)
        {
        }
        field(40;"Due Time";Time)
        {
        }
        field(41;"Helpdesk Feedback";Option)
        {
            OptionCaption = ' ,Bad,Satisfactory,Excellent';
            OptionMembers = " ",Bad,Satisfactory,Excellent;
        }
        field(42;"Maintenance Staff Feedback";Option)
        {
            OptionCaption = ' ,Bad,Satisfactory,Excellent';
            OptionMembers = " ",Bad,Satisfactory,Excellent;
        }
        field(43;"Completion Date";Date)
        {
        }
        field(44;"Completion Time";Time)
        {
        }
        field(45;"Completion Code";Code[10])
        {
            TableRelation = "Completion Code"."Completion Code";

            trigger OnValidate()
            var
                CompletionCodeRec: Record "Completion Code";
            begin
                IF "Completion Code" <> '' THEN BEGIN
                  CompletionCodeRec.GET("Completion Code");
                  "Completion Description" := CompletionCodeRec.Description;
                  "Completion Date" := TODAY;
                  "Completion Time" := TIME;
                END ELSE BEGIN
                  "Completion Description" := '';
                  "Completion Date" := 0D;
                  "Completion Time" := 0T;
                END;
                VALIDATE("WO Status");
            end;
        }
        field(46;"Completion Description";Text[30])
        {
            Editable = false;
        }
        field(47;"Client No.";Code[20])
        {
            TableRelation = Customer.No. WHERE (Client Type=FILTER(Client|Tenant));
        }
        field(48;"Alert Sent";Boolean)
        {
        }
        field(49;"Shortcut Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,2,1';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1,"Shortcut Dimension 1 Code");
            end;
        }
        field(50;"Shortcut Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,2,2';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2,"Shortcut Dimension 2 Code");
            end;
        }
        field(51;Comment;Boolean)
        {
            CalcFormula = Exist("Premise Comment" WHERE (Table Name=FILTER(Work Order),
                                                         No.=FIELD(No.)));
            FieldClass = FlowField;
        }
        field(52;"No. Series";Code[10])
        {
        }
        field(53;Closed;Boolean)
        {
            Editable = false;
        }
        field(54;"Approval Status";Option)
        {
            Editable = false;
            OptionCaption = 'Open,Released,Pending Approval';
            OptionMembers = Open,Released,"Pending Approval";

            trigger OnValidate()
            begin
                SendSMS;
            end;
        }
        field(55;"Currency Code";Code[10])
        {
            TableRelation = Currency;

            trigger OnValidate()
            begin
                TESTFIELD("Approval Status",0);
                IF "Currency Code" <> '' THEN BEGIN
                 UpdateCurrencyFactor;
                IF "Currency Factor" <> xRec."Currency Factor" THEN
                 ConfirmUpdateCurrencyFactor;
                 END;
                RecreateWorkOrderLines;
            end;
        }
        field(56;"Currency Factor";Decimal)
        {

            trigger OnValidate()
            begin

                IF "Currency Factor" <> xRec."Currency Factor" THEN
                  UpdateWorkOrderLines;
            end;
        }
        field(57;"Planned WO";Boolean)
        {
            Caption = 'Planned WO';
            Editable = false;
        }
    }

    keys
    {
        key(Key1;"Document Type","No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        WorkLineRec: Record "Work Order Line";
        MaintenanceCalendarLine: Record "Maintenance Calendar";
    begin
        TESTFIELD("Approval Status","Approval Status"::Open);

        WorkLineRec.RESET;
        WorkLineRec.SETRANGE("Document Type","Document Type");
        WorkLineRec.SETRANGE("Document No.","No.");
        WorkLineRec.SETFILTER("Converted Purch. Doc No.",'<>%1','');
        IF WorkLineRec.FINDFIRST THEN
          ERROR(Text001,WorkLineRec."Document Type",WorkLineRec."Document No.");

        WorkLineRec.SETRANGE("Converted Purch. Doc No.");
        WorkLineRec.SETFILTER("Converted Sales. Doc No.",'<>%1','');
        IF WorkLineRec.FINDFIRST THEN
          ERROR(Text002,WorkLineRec."Document Type",WorkLineRec."Document No.");

        DimMgt.DeleteDocDim(DATABASE::"Work Order Header","Document Type","No.",0);

        WorkLineRec.RESET;
        WorkLineRec.SETRANGE("Document Type","Document Type");
        WorkLineRec.SETRANGE("Document No.","No.");
        IF WorkLineRec.FINDSET THEN
          WorkLineRec.DELETEALL(TRUE);

        MaintenanceCalendarLine.SETRANGE("Work Order No.","No.");
        IF MaintenanceCalendarLine.FINDSET THEN BEGIN
          REPEAT
            MaintenanceCalendarLine."Work Order No." := '';
            MaintenanceCalendarLine.MODIFY;
          UNTIL MaintenanceCalendarLine.NEXT = 0;
        END;
    end;

    trigger OnInsert()
    var
        WorkPriorityRec: Record "Work Priority";
    begin
        "Document Type" := "Document Type"::"Work Order";
        PremiseMgt.GET;
        IF "No." = '' THEN BEGIN
          PremiseMgt.TESTFIELD("Work Order");
          NoSeriesMgt.InitSeries(PremiseMgt."Work Order",xRec."No. Series",0D,"No.","No. Series");
        END;
        IF "Date Created" = 0D THEN
          "Date Created" := TODAY;
        IF "Time Created" = 0T THEN
          "Time Created" := TIME;
        IF "User ID" = '' THEN
          "User ID" := USERID;

        WorkPriorityRec.RESET;
        WorkPriorityRec.SETRANGE(Default,TRUE);
        IF WorkPriorityRec.FINDFIRST THEN
          VALIDATE("Priority Code",WorkPriorityRec.Code)
        ELSE
          VALIDATE("Priority Code",'');


        DimMgt.InsertDocDim(DATABASE::"Work Order Header","Document Type","No.",0,
        "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
    end;

    trigger OnModify()
    var
        WorkOrderLine: Record "Work Order Line";
    begin
        IF ("Shortcut Dimension 1 Code" <> xRec."Shortcut Dimension 1 Code") OR
           ("Shortcut Dimension 2 Code" <> xRec."Shortcut Dimension 2 Code") THEN BEGIN
           WorkOrderLine.RESET;
           WorkOrderLine.SETRANGE("Document Type","Document Type");
           WorkOrderLine.SETRANGE("Document No.","No.");
           IF WorkOrderLine.FINDFIRST THEN REPEAT
             WorkOrderLine.VALIDATE("Shortcut Dimension 1 Code","Shortcut Dimension 1 Code");
             WorkOrderLine.VALIDATE("Shortcut Dimension 2 Code","Shortcut Dimension 2 Code");
             WorkOrderLine.MODIFY;
           UNTIL WorkOrderLine.NEXT = 0;
        END;

        "Last DateTime Modified" := CURRENTDATETIME;
        "Last User Modified" := USERID;
    end;

    var
        DimMgt: Codeunit "408";
        PremiseMgt: Record "Premise Management Setup";
        NoSeriesMgt: Codeunit "396";
        Text001: Label 'Purchase Document have been created from Work Order Type : %1 No. : %2.';
        Text002: Label 'Sales Document have been created from Work Order Type : %1 No. : %2.';
        WorkOrderLines: Record "Work Order Line";
        Text003: Label '&Active,&Cancel,Cl&ose';
        Text004: Label 'Do you want to change the Work Order Status of Work Order %1 from %2 to %3?';
        Text005: Label 'New Work Order can not be closed';
        Text006: Label 'You cannot change status of Cancelled Work Order';
        Text007: Label 'Action will delete all WO Res. Allocation Entries.Do you want to continue ?';
 
    procedure AssistEdit(OldWorkOrderRec: Record "Work Order Header"): Boolean
    begin
        PremiseMgt.GET;
        PremiseMgt.TESTFIELD("Work Order");
        IF NoSeriesMgt.SelectSeries(PremiseMgt."Work Order",OldWorkOrderRec."No. Series","No. Series") THEN BEGIN
          NoSeriesMgt.SetSeries("No.");
          EXIT(TRUE);
        END;
    end;
 
    procedure ValidateShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    var
        ChangeLogMgt: Codeunit "423";
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
        IF "No." <> '' THEN BEGIN
          DimMgt.SaveDocDim(
            DATABASE::"Work Order Header","Document Type","No.",0,FieldNumber,ShortcutDimCode);
          xRecRef.GETTABLE(xRec);
          MODIFY;
          RecRef.GETTABLE(Rec);
          ChangeLogMgt.LogModification(RecRef,xRecRef);
        END ELSE
          DimMgt.SaveTempDim(FieldNumber,ShortcutDimCode);
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
    end;
 
    procedure ShowDocumentDimension()
    var
        DocDim: Record "Document Dimension";
        DocDims: Form "546";
    begin
        DocDim.RESET;
        DocDim.SETRANGE("Table ID",DATABASE::"Work Order Header");
        DocDim.SETRANGE("Document No.","Premise/Facility No.");
        DocDim.SETRANGE("Line No.",0);
        DocDims.SETTABLEVIEW(DocDim);
        DocDims.RUNMODAL;
        GET("Document Type","No.");
    end;
 
    procedure SendSMS()
    var
        SMSIntegration: Codeunit "33016804";
        WorkResourceRec: Record "Work Order Resource";
        Resource: Record Resource;
        SMSIntegrationRec: Record "SMS Integration Setup";
    begin
        IF "Approval Status" <> xRec."Approval Status" THEN BEGIN
          SMSIntegrationRec.GET;
          IF (SMSIntegrationRec."Send SMS for Work Order") AND ("Approval Status" = "Approval Status"::Released) THEN BEGIN
            WorkResourceRec.RESET;
            WorkResourceRec.SETRANGE("Work Order No.","No.");
            WorkResourceRec.SETFILTER("Resource No.",'<>%1','');
            IF WorkResourceRec.FINDSET THEN REPEAT
              Resource.GET(WorkResourceRec."Resource No.");
              IF Resource."Resource Mobile No." <> '' THEN BEGIN
                SMSIntegration.SetReceiverName(Resource.Name);
                SMSIntegration.SetMobileNo(Resource."Resource Mobile No.");
                SMSIntegration.SetDescription(Description);
                SMSIntegration.RUN;
              END;
            UNTIL WorkResourceRec.NEXT = 0;
          END;
        END;
    end;
 
    procedure UpdateCurrencyFactor()
    var
        CurrencyDate: Date;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        IF "Currency Code" <> '' THEN
         BEGIN
            CurrencyDate := WORKDATE;
            "Currency Factor" := 1/CurrExchRate.ExchangeRate(CurrencyDate,"Currency Code");
           END ELSE
          "Currency Factor" := 0;
    end;
 
    procedure ConfirmUpdateCurrencyFactor()
    var
        HideValidationDialog: Boolean;
        Confirmed: Boolean;
        Text021: Label 'Do you want to update the exchange rate?';
    begin
        IF HideValidationDialog THEN
          Confirmed := TRUE
        ELSE
          Confirmed := CONFIRM(Text021,FALSE);
        IF Confirmed THEN
          VALIDATE("Currency Factor")
        ELSE
          "Currency Factor" := xRec."Currency Factor";
    end;
 
    procedure RecreateWorkOrderLines()
    var
        WorkOrderLine: Record "Work Order Line";
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        WorkOrderLineTmp: Record "Work Order Line" temporary;
    begin

        IF Currency.GET("Currency Code") THEN;
        IF WorkOrderLinesExist THEN
        BEGIN
        WorkOrderLine.SETRANGE("Document Type","Document Type");
        WorkOrderLine.SETRANGE("Document No.","No.");
        IF WorkOrderLine.FINDSET THEN
        REPEAT
        IF "Currency Code" <> '' THEN BEGIN
          WorkOrderLine."Cost Amount(LCY)" :=
            ROUND(
              CurrExchRate.ExchangeAmtLCYToFCY(
                WORKDATE,"Currency Code",
                WorkOrderLine."Cost Amount","Currency Factor"),
              Currency."Unit-Amount Rounding Precision");
          WorkOrderLine."Sales Amount(LCY)" :=
            ROUND(
              CurrExchRate.ExchangeAmtLCYToFCY(
                WORKDATE,"Currency Code",
                WorkOrderLine."Sales Amount","Currency Factor"),
              Currency."Unit-Amount Rounding Precision");
        END ELSE BEGIN
          WorkOrderLine."Cost Amount(LCY)" := WorkOrderLine."Cost Amount";
            WorkOrderLine."Sales Amount(LCY)" := WorkOrderLine."Sales Amount";
          END;
          WorkOrderLine.MODIFY;
          UNTIL WorkOrderLine.NEXT=0;
        END
    end;
 
    procedure WorkOrderLinesExist(): Boolean
    var
        AgreementLines: Record "Agreement Line";
    begin
        WorkOrderLines.RESET;
        WorkOrderLines.SETRANGE("Document Type","Document Type");
        WorkOrderLines.SETRANGE("Document No.","No.");
        EXIT(WorkOrderLines.FINDFIRST);
    end;
 
    procedure UpdateWorkOrderLines()
    var
        WorkOrderLine: Record "Work Order Line";
    begin
        WorkOrderLine.RESET;
        WorkOrderLine.SETRANGE("Document Type","Document Type");
        WorkOrderLine.SETRANGE("Document No.","No.");
        IF WorkOrderLine.FINDFIRST THEN REPEAT
          WorkOrderLine.VALIDATE("Currency Code","Currency Code");
          WorkOrderLine.MODIFY(TRUE);
        UNTIL WorkOrderLine.NEXT = 0;
    end;
 
    procedure UpdateWorkOrderStatus()
    var
        WOStatus: Option New,Active,Cancelled,Closed;
        WorkOrderHeader: Record "Work Order Header";
        OldStatus: Option New,Active,Cancelled,Closed;
        WorkOrderHeader1: Record "Work Order Header";
        Selection: Integer;
    begin
        WorkOrderHeader.GET("Document Type","No.");
        WITH WorkOrderHeader DO BEGIN
          OldStatus := WorkOrderHeader."WO Status";
          WOStatus := WorkOrderHeader."WO Status";
          IF OldStatus = OldStatus::Cancelled THEN
            ERROR(Text006);
          Selection := STRMENU(Text003,0);
          CASE Selection OF
          1 :
            BEGIN
              WOStatus := "WO Status"::Active;
            END;
          2 :
            BEGIN
              WOStatus := "WO Status"::Cancelled;
            END;
          3 :
            BEGIN
              WOStatus := "WO Status"::Closed;
            END;
          END;
          IF WOStatus <> OldStatus THEN BEGIN
            IF CONFIRM(Text004,FALSE,WorkOrderHeader."No.",OldStatus,
              WOStatus) THEN BEGIN
                WorkOrderHeader1 := WorkOrderHeader;
                WorkOrderHeader1.VALIDATE("WO Status",WOStatus);
                WorkOrderHeader1.MODIFY;
            END;
          END;
        END;
    end;
 
    procedure CreateResourceAllocation()
    var
        WorkOrderRec: Record "Work Order Header";
        WorkOrderLineRec: Record "Work Order Line";
        WoResAllocation: Record "WO Res. Allocation";
        LineNo: Integer;
        i: Integer;
        WorkOrderLineRec1: Record "Work Order Line";
        WorkOrderLineRec2: Record "Work Order Line";
        WoResAllocation2: Record "WO Res. Allocation";
        WOResAllocationEntries: Record "WO Res. Allocation Entries";
    begin
        WorkOrderRec.GET("Document Type","No.");
        IF WorkOrderRec."WO Status" = WorkOrderRec."WO Status"::New THEN BEGIN
          WorkOrderLineRec.RESET;
          WorkOrderLineRec.SETRANGE("Document Type",WorkOrderRec."Document Type");
          WorkOrderLineRec.SETRANGE("Document No.",WorkOrderRec."No.");
          WorkOrderLineRec.SETRANGE(Type,WorkOrderLineRec.Type::Task);
          WorkOrderLineRec.SETRANGE("Allocation Entries Created",FALSE);
          WorkOrderLineRec.SETFILTER("No. of Resources",'<>%1',0);
          IF WorkOrderLineRec.FINDSET THEN BEGIN
            REPEAT
              WoResAllocation2.RESET;
              WoResAllocation2.SETRANGE("Work Order No.",WorkOrderRec."No.");
              WoResAllocation2.SETRANGE("Work Order Line No.",WorkOrderLineRec."Document Line No.");
              WoResAllocation2.DELETEALL;

              WOResAllocationEntries.RESET;
              WOResAllocationEntries.SETRANGE("Work Order No.",WorkOrderRec."No.");
              WOResAllocationEntries.DELETEALL;

              FOR i := 1 TO WorkOrderLineRec."No. of Resources" DO BEGIN
                WoResAllocation.INIT;
                WoResAllocation.VALIDATE("Work Order No.",WorkOrderLineRec."Document No.");
                WoResAllocation.VALIDATE("Work Order Line No.",WorkOrderLineRec."Document Line No.");
                WoResAllocation.VALIDATE("Task Code",WorkOrderLineRec.Code);
                WoResAllocation.VALIDATE("Planned Date",WorkOrderLineRec."Planned Date");
                WoResAllocation."Line  No." := i * 10000;
                WoResAllocation.VALIDATE(UOM,WorkOrderLineRec."Unit of Measure Code");
                WoResAllocation.VALIDATE("Task Type",WorkOrderLineRec."Task Type");
                WoResAllocation.INSERT(TRUE);
              END;
              WorkOrderLineRec1 := WorkOrderLineRec;
              WorkOrderLineRec1."Allocation Entries Created" := TRUE;
              WorkOrderLineRec1.MODIFY;
            UNTIL WorkOrderLineRec.NEXT = 0;
          END;
        END;
    end;
 
    procedure DeleteAllocationEntries()
    var
        WoResAllocation: Record "WO Res. Allocation";
        WOResAllocationEntries: Record "WO Res. Allocation Entries";
    begin
        WoResAllocation.RESET;
        WoResAllocation.SETRANGE("Work Order No.","No.");
        WoResAllocation.DELETEALL;

        WOResAllocationEntries.RESET;
        WOResAllocationEntries.SETRANGE("Work Order No.","No.");
        WOResAllocationEntries.DELETEALL;
    end;
 
    procedure TestPremiseBlocked()
    var
        Premise: Record Premise;
    begin
        IF "Request From" = "Request From"::Premise THEN BEGIN
          IF Premise.GET("Premise/Facility No.") THEN BEGIN
            Premise.TESTFIELD(Blocked,FALSE);
          END;
        END;
    end;
 
    procedure TestStatusOpen()
    var
        WorkRec: Record "Work Order Header";
    begin
        WorkRec.RESET;
        IF WorkRec.GET("Document Type","No.") THEN
          WorkRec.TESTFIELD("Approval Status",WorkRec."Approval Status"::Open);
    end;
}

