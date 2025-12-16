table 33016801 "Event Detail"
{
    Caption = 'Event';
    DrillDownFormID = Form33016801;
    LookupFormID = Form33016801;

    fields
    {
        field(1; "No."; Code[20])
        {

            trigger OnValidate()
            begin
                IF "No." <> xRec."No." THEN BEGIN
                    PremiseMgtSetup.GET;
                    NoSeriesMgt.TestManual(PremiseMgtSetup."Event No.");
                    "No. Series" := '';
                END;
            end;
        }
        field(2; Name; Text[50])
        {

            trigger OnValidate()
            begin
                TESTFIELD(Status, Status::New);
            end;
        }
        field(3; "Event Period"; DateFormula)
        {

            trigger OnValidate()
            begin
                ValidateEndDate;
            end;
        }
        field(4; "Start Date"; Date)
        {

            trigger OnValidate()
            begin
                ValidateEndDate;
            end;
        }
        field(5; "End Date"; Date)
        {

            trigger OnValidate()
            begin
                ValidateEndDate;
            end;
        }
        field(6; "Event Type"; Code[20])
        {
            TableRelation = "Event Type";

            trigger OnValidate()
            begin
                TESTFIELD(Status, Status::New);

                EventTypeRec.GET("Event Type");
                IF EventTypeRec."Maintenance Event" THEN
                    "Maintenance Event" := TRUE
                ELSE
                    "Maintenance Event" := FALSE;
            end;
        }
        field(7; Status; Option)
        {
            Editable = false;
            OptionCaption = 'New,Active,Cancelled,Closed';
            OptionMembers = New,Active,Cancelled,Closed;

            trigger OnValidate()
            begin
                IF Status <> xRec.Status THEN BEGIN
                    IF Status = Status::Closed THEN BEGIN
                        IF xRec.Status = xRec.Status::New THEN
                            ERROR(Text005);
                    END;
                    IF Status = Status::Cancelled THEN BEGIN
                        IF xRec.Status = xRec.Status::Active THEN
                            ERROR(Text007);
                    END;
                END;
            end;
        }
        field(8; "Event Manager"; Code[10])
        {
            TableRelation = Salesperson/Purchaser;

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::New);
            end;
        }
        field(9;"Resource Type";Option)
        {
            OptionCaption = 'Individual,Group';
            OptionMembers = Individual,Group;

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::New);

                IF "Resource Type" <> xRec."Resource Type" THEN
                  "Resource No./Group" := '';
                SetLinkedVendor;
            end;
        }
        field(10;"Resource No./Group";Code[20])
        {
            TableRelation = IF (Resource Type=CONST(Individual)) Resource
                            ELSE IF (Resource Type=CONST(Group)) "Resource Group";

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::New);
                SetLinkedVendor;
            end;
        }
        field(11;"No. of Premises";Integer)
        {
            CalcFormula = Count("Premise Events" WHERE (Event Code=FIELD(No.)));
            Editable = false;
            FieldClass = FlowField;

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::New);
            end;
        }
        field(12;"Maintenance Event";Boolean)
        {
            Editable = false;

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::New);
            end;
        }
        field(13;"Opportunity Code";Code[20])
        {
            TableRelation = Opportunity.No.;

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::New);
            end;
        }
        field(14;"Global Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,1,1';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::New);
                ValidateShortcutDimCode(1,"Global Dimension 1 Code");
            end;
        }
        field(15;"Global Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,1,2';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::New);
                ValidateShortcutDimCode(1,"Global Dimension 1 Code");
            end;
        }
        field(16;"No. Series";Code[10])
        {
            TableRelation = "No. Series";
        }
        field(17;Comment;Boolean)
        {
            CalcFormula = Exist("Premise Comment" WHERE (Table Name=CONST(Event),
                                                         No.=FIELD(No.)));
            Editable = false;
            FieldClass = FlowField;

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::New);
            end;
        }
        field(18;"Linked Budget Code";Code[10])
        {
            TableRelation = "G/L Budget Name";

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::New);
            end;
        }
        field(19;"Linked Vendor";Code[20])
        {
            TableRelation = Vendor;

            trigger OnValidate()
            begin
                TESTFIELD(Status,Status::New);
                SetLinkedVendor;
            end;
        }
    }

    keys
    {
        key(Key1;"No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        CommentLine: Record "Comment Line";
    begin
        TESTFIELD(Status,Status::New);

        CommentLine.SETRANGE("Table Name",CommentLine."Table Name"::"17");
        CommentLine.SETRANGE("No.","No.");
        CommentLine.DELETEALL;

        DimMgt.DeleteDefaultDim(DATABASE::"Event","No.");
    end;

    trigger OnInsert()
    begin
        IF "No." = '' THEN BEGIN
          PremiseMgtSetup.GET;
          PremiseMgtSetup.TESTFIELD("Event No.");
          NoSeriesMgt.InitSeries(PremiseMgtSetup."Event No.",xRec."No. Series",0D,"No.","No. Series");
        END;

        DimMgt.UpdateDefaultDim(DATABASE::"Event","No.","Global Dimension 1 Code","Global Dimension 2 Code");
    end;

    var
        PremiseMgtSetup: Record "Premise Management Setup";
        NoSeriesMgt: Codeunit "396";
        DimMgt: Codeunit "408";
        EventTypeRec: Record "Event Type";
        Text001: Label 'Linked Vendor No. %1 on Event No. %2 is different than the Vendor No. %3 specfied on the Resource %4';
        Text003: Label '&Active,&Cancel,Cl&ose';
        Text004: Label 'Do you want to change the Event Status of Event %1 from %2 to %3?';
        Text005: Label 'New Event can not be closed';
        Text006: Label 'You cannot change status of cancelled Event';
        Text007: Label 'Active Event cannot be cancelled';
        Text008: Label 'Event %1 is %2';
 
    procedure AssistEdit(OldEvent: Record "Event Detail"): Boolean
    var
        EventRec: Record "Event Detail";
    begin
        WITH EventRec DO BEGIN
          EventRec := Rec;
          PremiseMgtSetup.GET;
          PremiseMgtSetup.TESTFIELD("Event No.");
          IF NoSeriesMgt.SelectSeries(PremiseMgtSetup."Event No.",OldEvent."No. Series","No. Series") THEN BEGIN
            NoSeriesMgt.SetSeries("No.");
            Rec := EventRec;
            EXIT(TRUE);
          END;
        END;
    end;
 
    procedure ValidateShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
        DimMgt.SaveDefaultDim(DATABASE::"Event","No.",FieldNumber,ShortcutDimCode);
        MODIFY;
    end;
 
    procedure SetLinkedVendor()
    var
        Resource: Record Resource;
    begin
        IF "Resource Type" = "Resource Type"::Individual THEN BEGIN
          IF NOT Resource.GET("Resource No./Group") THEN
            "Linked Vendor" := ''
          ELSE BEGIN
            IF Resource."Resource Type" = Resource."Resource Type"::External THEN BEGIN
              IF "Linked Vendor" = '' THEN
                "Linked Vendor" := Resource."Linked Vendor"
              ELSE
                TESTFIELD("Linked Vendor",Resource."Linked Vendor");
            END ELSE
              "Linked Vendor" := '';
          END;
        END ELSE
          "Linked Vendor" := '';
    end;
 
    procedure ValidateEndDate()
    begin
        TESTFIELD(Status,Status::New);
        IF ("Start Date" <> 0D) AND (FORMAT("Event Period") <> '') THEN BEGIN
          "End Date" := CALCDATE("Event Period","Start Date");
          "End Date" := "End Date" - 1;
        END ELSE
          "End Date" := 0D;
    end;
 
    procedure UpdateWorkOrderStatus()
    var
        WOStatus: Option New,Active,Cancelled,Closed;
        EventDetail: Record "Event Detail";
        OldStatus: Option New,Active,Cancelled,Closed;
        EventDetail1: Record "Event Detail";
        Selection: Integer;
    begin
        EventDetail.GET("No.");
        WITH EventDetail DO BEGIN
          OldStatus := EventDetail.Status;
          IF OldStatus IN [OldStatus::New,OldStatus::Active] THEN BEGIN
            WOStatus := EventDetail.Status;
            IF OldStatus = OldStatus::Cancelled THEN
              ERROR(Text006);

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
                IF CONFIRM(Text004,FALSE,EventDetail."No.",OldStatus,
                  WOStatus) THEN BEGIN
                   EventDetail1 := EventDetail;
                   EventDetail1.VALIDATE(Status,WOStatus);
                   EventDetail1.MODIFY;
                END;
              END;
          END ELSE
            ERROR(Text008,EventDetail."No.",EventDetail.Status);
        END;
    end;
}

