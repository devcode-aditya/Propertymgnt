table 33016818 "Call Register"
{
    Caption = 'Call Register';
    LookupFormID = Form33016823;

    fields
    {
        field(1; "Document Type"; Option)
        {
            OptionCaption = 'Work Request';
            OptionMembers = "Work Request";
        }
        field(2; "No."; Code[20])
        {

            trigger OnValidate()
            begin
                IF "No." <> xRec."No." THEN BEGIN
                    PremiseMgtSetup.GET;
                    NoSeriesMgt.TestManual(PremiseMgtSetup."Call Register");
                    "No. Series" := '';
                END;
            end;
        }
        field(3; "Request From Type"; Option)
        {
            OptionCaption = 'Premise,Facility';
            OptionMembers = Premise,Facility;

            trigger OnValidate()
            begin
                IF "Request From Type" <> xRec."Request From Type" THEN BEGIN
                    "Premise/Facility No." := '';
                    Name := '';
                    "Premise/Sub-Premise" := 0;
                    City := '';
                    "Floor No." := '';
                    "Shortcut Dimension 1 Code" := '';
                    "Shortcut Dimension 2 Code" := '';
                    "Subunit Code" := '';
                    "Subunit Description" := '';
                END;
            end;
        }
        field(4; "Premise/Facility No."; Code[20])
        {
            TableRelation = IF (Request From Type=FILTER(Premise)) Premise.No.
                            ELSE IF (Request From Type=FILTER(Facility)) Facility.No.;

            trigger OnValidate()
            begin
                CASE "Request From Type" OF
                  "Request From Type"::Premise:
                  BEGIN
                    IF "Premise/Facility No." <> '' THEN BEGIN
                      PremiseRec.GET("Premise/Facility No.");
                      Name := PremiseRec.Name;
                      "Premise/Sub-Premise" := PremiseRec."Premise/Sub-Premise";
                      City := PremiseRec.City;
                      "Floor No." := PremiseRec."Floor No.";
                      VALIDATE("Shortcut Dimension 1 Code",PremiseRec."Global Dimension 1 Code");
                      VALIDATE("Shortcut Dimension 2 Code",PremiseRec."Global Dimension 2 Code");
                    END ELSE BEGIN
                      CLEAR(Name);
                      CLEAR("Premise/Sub-Premise");
                      CLEAR(City);
                      CLEAR("Floor No.");
                      VALIDATE("Shortcut Dimension 1 Code",'');
                      VALIDATE("Shortcut Dimension 2 Code",'');
                    END;
                  END;
                  "Request From Type"::Facility:
                  BEGIN
                    IF "Premise/Facility No." <> '' THEN BEGIN
                      FacilityRec.GET("Premise/Facility No.");
                      Name := FacilityRec.Name;
                      "Floor No." := FacilityRec."Floor No.";
                      VALIDATE("Shortcut Dimension 1 Code",FacilityRec."Global Dimension 1 Code");
                      VALIDATE("Shortcut Dimension 2 Code",FacilityRec."Global Dimension 2 Code");
                    END ELSE BEGIN
                      "Floor No." := '';
                      VALIDATE("Shortcut Dimension 1 Code",'');
                      VALIDATE("Shortcut Dimension 2 Code",'');
                      CLEAR(Name);
                    END;
                  END;
                END;
            end;
        }
        field(5;"Premise/Sub-Premise";Option)
        {
            Editable = false;
            OptionCaption = 'Premise,Sub-Premise';
            OptionMembers = Premise,"Sub-Premise";
        }
        field(6;"Subunit Code";Code[20])
        {
            TableRelation = "Premise Subunit".Code WHERE (Premise Code=FIELD(Premise/Facility No.));

            trigger OnValidate()
            var
                PremiseSubunitRec: Record "Premise Subunit";
            begin
                IF "Subunit Code" <> '' THEN BEGIN
                  PremiseSubunitRec.GET("Premise/Facility No.","Subunit Code");
                  "Subunit Description" := PremiseSubunitRec.Description;
                END ELSE
                  "Subunit Description" := '';
            end;
        }
        field(7;"Floor No.";Code[20])
        {
            Editable = false;
            TableRelation = "Premise Floor"."Floor No.";
        }
        field(8;Contact;Code[20])
        {
            TableRelation = IF (Request From Type=FILTER(Premise)) "Premise Contact".No. WHERE (Premise Code=FIELD(Premise/Facility No.))
                            ELSE IF (Request From Type=FILTER(Facility)) "Facility Contact".No. WHERE (Facility Code=FIELD(Premise/Facility No.));

            trigger OnValidate()
            var
                PremiseContactRec: Record "Premise Contact";
                FacilityContactRec: Record "Facility Contact";
            begin
                IF Contact <> '' THEN BEGIN
                  TESTFIELD("Premise/Facility No.");
                  IF "Request From Type" = "Request From Type"::Premise THEN BEGIN
                     PremiseContactRec.GET("Premise/Facility No.",Contact);
                     "Contact Name" := PremiseContactRec.Name;
                     "Call Back No." := PremiseContactRec."Phone No.";
                     "Contact Method" := PremiseContactRec."Contact Method";
                  END ELSE BEGIN
                     FacilityContactRec.GET("Premise/Facility No.",Contact);
                     "Contact Name" := FacilityContactRec.Name;
                     "Call Back No." := FacilityContactRec."Phone No.";
                     "Contact Method":= FacilityContactRec."Contact Method";

                  END;
                END ELSE BEGIN
                  CLEAR("Contact Name");
                  CLEAR("Call Back No.");
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
            Caption = 'Call Description';
        }
        field(12;"Priority Code";Code[10])
        {
            TableRelation = "Work Priority".Code;

            trigger OnValidate()
            var
                PriorityRec: Record "Work Priority";
            begin
                IF "Priority Code" <> '' THEN BEGIN
                  PriorityRec.GET("Priority Code");
                  "Priority Description" := PriorityRec.Description;
                END ELSE
                  "Priority Description" := '';
            end;
        }
        field(13;Status;Option)
        {
            Editable = false;
            OptionCaption = 'New,Active,Cancelled,Closed';
            OptionMembers = New,Active,Cancelled,Closed;

            trigger OnValidate()
            var
                CompletionCodeRec: Record "Completion Code";
            begin
                IF Status <> xRec.Status THEN BEGIN
                  IF Status = Status::Closed THEN BEGIN
                    IF xRec.Status = xRec.Status::New THEN
                      ERROR(Text005);
                    Closed := TRUE;
                  END;
                  IF Status = Status::Cancelled THEN BEGIN
                    IF xRec.Status = xRec.Status::Active THEN
                      ERROR(Text007);
                    Closed := TRUE;
                  END;
                END;
            end;
        }
        field(14;"Call Date";Date)
        {
            Caption = 'Date';
            Editable = false;
        }
        field(15;"Call Time";Time)
        {
            Caption = 'Time';
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
            TableRelation = User;
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
        field(23;"Priority Description";Text[30])
        {
            Editable = false;
        }
        field(25;Converted;Boolean)
        {
            Editable = false;
        }
        field(26;"Conversion Date Time";DateTime)
        {
            Editable = false;
        }
        field(27;"Client No.";Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = Customer.No. WHERE (Client Type=FILTER(Tenant|Client));
        }
        field(28;"No. Series";Code[10])
        {
            TableRelation = "No. Series";
        }
        field(29;"Alert Sent";Boolean)
        {
        }
        field(30;"Shortcut Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,2,1';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1,"Shortcut Dimension 1 Code");
            end;
        }
        field(31;"Shortcut Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,2,2';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2,"Shortcut Dimension 2 Code");
            end;
        }
        field(32;Comment;Boolean)
        {
            CalcFormula = Exist("Premise Comment" WHERE (Table Name=FILTER(Call Register),
                                                         No.=FIELD(No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(33;Closed;Boolean)
        {
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
        WorkOrderRec: Record "Work Order Header";
    begin
        IF Converted THEN BEGIN
          WorkOrderRec.RESET;
          WorkOrderRec.SETRANGE("Converted From","No.");
          IF WorkOrderRec.FINDFIRST THEN;
          ERROR(Text001,"Document Type","No.",WorkOrderRec."Document Type",WorkOrderRec."No.");
        END;
    end;

    trigger OnInsert()
    var
        PriorityRec: Record "Work Priority";
    begin
        "Document Type" := "Document Type"::"Work Request";
        IF "No." = '' THEN BEGIN
          PremiseMgtSetup.GET;
          PremiseMgtSetup.TESTFIELD("Call Register");
          NoSeriesMgt.InitSeries(PremiseMgtSetup."Call Register",xRec."No. Series",0D,"No.","No. Series");
        END;

        "Call Date" := TODAY;
        "Call Time" := TIME;
        "User ID" := USERID;
        Status := Status::New;

        PriorityRec.RESET;
        PriorityRec.SETRANGE(Default,TRUE);
        IF PriorityRec.FINDFIRST THEN
          VALIDATE("Priority Code",PriorityRec.Code)
    end;

    trigger OnModify()
    begin
        "Last DateTime Modified" := CREATEDATETIME(TODAY,"Call Time");
        "Last User Modified" := USERID;
    end;

    var
        NoSeriesMgt: Codeunit "396";
        PremiseMgtSetup: Record "Premise Management Setup";
        PremiseRec: Record Premise;
        FacilityRec: Record Facility;
        DimMgt: Codeunit "408";
        Text001: Label 'Call Register Type %1 No. %2  is already into Call Register Type %3  No. %4';
        Text003: Label '&Active,&Cancel,Cl&ose';
        Text004: Label 'Do you want to change the Call Register Status of Call Register %1 from %2 to %3?';
        Text005: Label 'New Call Register can not be closed';
        Text006: Label 'You cannot change status of cancelled Call Register';
        Text007: Label 'Active Call Register cannot be cancelled';
 
    procedure AssistEdit(OldCallRegistration: Record "Call Register"): Boolean
    var
        CallRegistrationRec: Record "Call Register";
    begin
        PremiseMgtSetup.GET;
        PremiseMgtSetup.TESTFIELD("Call Register");
        IF NoSeriesMgt.SelectSeries(PremiseMgtSetup."Call Register",OldCallRegistration."No. Series","No. Series") THEN BEGIN
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
            DATABASE::"Call Register","Document Type","No.",0,FieldNumber,ShortcutDimCode);
          xRecRef.GETTABLE(xRec);
          MODIFY;
          RecRef.GETTABLE(Rec);
          ChangeLogMgt.LogModification(RecRef,xRecRef);
        END ELSE
          DimMgt.SaveTempDim(FieldNumber,ShortcutDimCode);
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
    end;
 
    procedure UpdateWorkOrderStatus()
    var
        WOStatus: Option New,Active,Cancelled,Closed;
        CallRegister: Record "Call Register";
        OldStatus: Option New,Active,Cancelled,Closed;
        CallRegister1: Record "Call Register";
        Selection: Integer;
    begin
        CallRegister.GET("Document Type","No.");
        WITH CallRegister DO BEGIN
          TESTFIELD("Premise/Facility No.");
          OldStatus := CallRegister.Status;
          IF OldStatus = OldStatus::Cancelled THEN
            ERROR(Text006);

          WOStatus := CallRegister.Status;
          Selection := STRMENU(Text003,0);
          CASE Selection OF
          1 :
            BEGIN
              WOStatus := Status::Active;
            END;
          2 :
            BEGIN
              WOStatus := Status::Cancelled;
            END;
          3 :
            BEGIN
              WOStatus := Status::Closed;
            END;
          END;
            IF WOStatus <> OldStatus THEN BEGIN
              IF CONFIRM(Text004,FALSE,CallRegister."No.",OldStatus,
                WOStatus) THEN BEGIN
                CallRegister1 := CallRegister;
                CallRegister1.VALIDATE(Status,WOStatus);
                CallRegister1.MODIFY;
              END;
            END;
        END;
    end;
}

