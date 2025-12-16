table 33016814 Premise
{
    Caption = 'Premise';
    DrillDownFormID = Form33016803;
    LookupFormID = Form33016803;

    fields
    {
        field(1; "No."; Code[20])
        {

            trigger OnValidate()
            begin
                IF "No." <> xRec."No." THEN BEGIN
                    PremiseMgtSetup.GET;
                    NoSeriesMgt.TestManual(PremiseMgtSetup.Premise);
                    "No. Series" := '';
                END;
            end;
        }
        field(2; Name; Text[50])
        {

            trigger OnValidate()
            var
                PremiseRec: Record Premise;
            begin

                IF "Premise/Sub-Premise" = "Premise/Sub-Premise"::Premise THEN BEGIN
                    VALIDATE("Premise/Sub-Premise");
                    PremiseRec.RESET;
                    PremiseRec.SETRANGE("Premise/Sub-Premise", "Premise/Sub-Premise"::"Sub-Premise");
                    PremiseRec.SETRANGE("Sub-Premise of Premise", "No.");
                    IF PremiseRec.FINDSET THEN
                        REPEAT
                            PremiseRec."Premise Name" := Name;
                            PremiseRec.MODIFY;
                        UNTIL PremiseRec.NEXT = 0;
                END;
            end;
        }
        field(3; "Premise/Sub-Premise"; Option)
        {
            OptionCaption = 'Premise,Sub-Premise';
            OptionMembers = Premise,"Sub-Premise";

            trigger OnValidate()
            var
                PremiseRec: Record Premise;
            begin
                IF ("Premise/Sub-Premise" <> xRec."Premise/Sub-Premise") THEN BEGIN
                    "Premise Group" := '';
                    "Premise Sub Group" := '';
                    IF ("Premise/Sub-Premise" = "Premise/Sub-Premise"::"Sub-Premise") THEN BEGIN
                        PremiseRec.RESET;
                        PremiseRec.SETRANGE("Premise/Sub-Premise", PremiseRec."Premise/Sub-Premise"::"Sub-Premise");
                        PremiseRec.SETRANGE("Sub-Premise of Premise", "No.");
                        IF PremiseRec.FINDFIRST THEN
                            ERROR(Text002, "No.", PremiseRec."No.");
                    END;
                END;

                IF "Premise/Sub-Premise" = "Premise/Sub-Premise"::Premise THEN
                    VALIDATE("Sub-Premise of Premise", "No.")
                ELSE
                    VALIDATE("Sub-Premise of Premise", '');
            end;
        }
        field(4; "Sub-Premise of Premise"; Code[20])
        {
            TableRelation = IF (Premise/Sub-Premise=FILTER(Sub-Premise)) Premise.No. WHERE (Premise/Sub-Premise=FILTER(Premise));

            trigger OnValidate()
            begin
                IF "Premise/Sub-Premise" <> "Premise/Sub-Premise"::Premise THEN BEGIN
                  IF "Sub-Premise of Premise" <> '' THEN BEGIN
                    Premise.GET("Sub-Premise of Premise");
                    "Premise Name" := Premise.Name;
                    Address := Premise.Address;
                    Address2 := Premise.Address2;
                    "Floor No." := Premise."Floor No.";
                    VALIDATE("Post Code",Premise."Post Code");
                    City := Premise.City;
                    "Country Code" := Premise."Country Code";
                    "Region Code" := Premise."Region Code";
                    "Premise Group" := Premise."Premise Group";
                    "Premise Sub Group" := Premise."Premise Sub Group";
                    "Premise Group" := Premise."Premise Group";
                    "Premise Sub Group" := Premise."Premise Sub Group";
                  END ELSE BEGIN
                    "Premise Name" := '';
                    ResetPremiseInfo;
                  END;
                END ELSE BEGIN
                  "Premise Name" := Name;
                  IF ("Premise/Sub-Premise" <> xRec."Premise/Sub-Premise") THEN
                    ResetPremiseInfo;
                END;
            end;
        }
        field(5;"Premise Group";Code[20])
        {
            TableRelation = "Premise Group";
        }
        field(6;"Premise Sub Group";Code[20])
        {
            TableRelation = "Premise Sub Group".Code WHERE (Premise Group=FIELD(Premise Group));
        }
        field(7;"Floor No.";Code[10])
        {
            TableRelation = "Premise Floor"."Floor No.";
        }
        field(8;Address;Text[50])
        {
        }
        field(9;Address2;Text[50])
        {
        }
        field(10;"Post Code";Code[20])
        {
            TableRelation = "Post Code";

            trigger OnLookup()
            begin
                PostCode.LookUpPostCode(City,"Post Code",TRUE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City,"Post Code");
            end;
        }
        field(11;City;Text[30])
        {
            TableRelation = "Post Code".City WHERE (Code=FIELD(Post Code));

            trigger OnLookup()
            begin
                PostCode.LookUpPostCode(City,"Post Code",TRUE);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City,"Post Code");
            end;
        }
        field(12;"Country Code";Code[10])
        {
            TableRelation = Country/Region;

            trigger OnValidate()
            begin
                IF "Country Code" = '' THEN
                  "Region Code" := '';
            end;
        }
        field(13;"Region Code";Code[10])
        {

            trigger OnLookup()
            var
                CountryRec: Record "Country/Region";
                CountriesForm: Form "10";
            begin
                CLEAR(CountriesForm);
                CountryRec.RESET;
                CountryRec.SETRANGE(Code,"Country Code");
                CountriesForm.SETTABLEVIEW(CountryRec);
                CountriesForm.LOOKUPMODE(TRUE);
                IF CountriesForm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                  CountriesForm.GETRECORD(CountryRec);
                  "Region Code" := CountryRec."EU Country/Region Code";
                END;
            end;
        }
        field(14;"Premise Type";Code[20])
        {
            TableRelation = "Premise Unit Type".Code;
        }
        field(15;"Premise Manager";Code[10])
        {
            TableRelation = Salesperson/Purchaser;
        }
        field(16;"Premise Status";Option)
        {
            Editable = false;
            OptionCaption = 'Vacant,Booked,Sold,On Lease';
            OptionMembers = Vacant,Booked,Sold,"On Lease";
        }
        field(17;"No. of Units";Integer)
        {
            BlankZero = true;
            CalcFormula = Count(Premise WHERE (Premise/Sub-Premise=CONST(Sub-Premise),
                                               Sub-Premise of Premise=FIELD(No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(18;Blocked;Boolean)
        {
            Editable = false;
        }
        field(19;Picture;BLOB)
        {
            SubType = Bitmap;
        }
        field(20;"Built-up Area";Decimal)
        {
            BlankZero = true;
            MinValue = 0;
        }
        field(21;"Leasable/Salable Area";Decimal)
        {
            BlankZero = true;
            MinValue = 0;

            trigger OnValidate()
            begin
                "Total Area" := "Leasable/Salable Area" + "Non Leasable/Salable Area";
            end;
        }
        field(22;"Unit of Measure";Code[10])
        {
            TableRelation = "Unit of Measure";
        }
        field(23;"Agreement Type";Option)
        {
            Editable = false;
            OptionCaption = 'Lease,Sale';
            OptionMembers = Lease,Sale;
        }
        field(24;"Client No.";Code[20])
        {
            Editable = false;

            trigger OnLookup()
            var
                ClientFrm: Form "33016840";
                ClientRec: Record Customer;
            begin
                CLEAR(ClientFrm);
                ClientRec.RESET;
                ClientRec.SETFILTER("Client Type",'%1|%2',ClientRec."Client Type"::Client,ClientRec."Client Type"::Tenant);
                ClientFrm.SETTABLEVIEW(ClientRec);
                ClientFrm.LOOKUPMODE(TRUE);
                ClientFrm.SETRECORD(ClientRec);
                IF ClientFrm.RUNMODAL = ACTION::LookupOK THEN;
            end;
        }
        field(25;"Client Name";Text[50])
        {
            Editable = false;
        }
        field(26;"Client Mobile No.";Text[30])
        {
            Editable = false;
        }
        field(27;"Client Phone No.";Text[30])
        {
            Editable = false;
        }
        field(28;"Client E-Mail";Text[80])
        {
            Editable = false;
        }
        field(29;"Global Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,1,1';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1,"Global Dimension 1 Code");
            end;
        }
        field(30;"Global Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,1,2';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2,"Global Dimension 2 Code");
            end;
        }
        field(31;"No. Series";Code[10])
        {
            TableRelation = "No. Series".Code;
        }
        field(32;"Premise Name";Text[50])
        {
            Editable = false;
        }
        field(33;Comment;Boolean)
        {
            CalcFormula = Exist("Premise Comment" WHERE (Table Name=FILTER(Premise),
                                                         No.=FIELD(No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(34;"Super Area";Decimal)
        {
            BlankZero = true;
            MinValue = 0;
        }
        field(35;"Carpet Area";Decimal)
        {
            BlankZero = true;
            MinValue = 0;
        }
        field(36;"Agreement No.";Code[20])
        {
            Editable = false;
        }
        field(37;"No. of Work Order";Integer)
        {
            BlankZero = true;
            CalcFormula = Count("Work Order Header" WHERE (Request From=FILTER(Premise),
                                                           Premise/Facility No.=FILTER(<>''),
                                                           Premise/Facility No.=FIELD(No.),
                                                           WO Status=FILTER(<>Cancelled)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(38;"Non Leasable/Salable Area";Decimal)
        {
            BlankZero = true;
            MinValue = 0;

            trigger OnValidate()
            begin
                "Total Area" := "Leasable/Salable Area" + "Non Leasable/Salable Area";
            end;
        }
        field(39;"Total Area";Decimal)
        {
            BlankZero = true;
            Editable = false;
        }
        field(40;"Sub Premise Total L/S";Decimal)
        {
            CalcFormula = Sum(Premise."Leasable/Salable Area" WHERE (Premise/Sub-Premise=FILTER(Sub-Premise),
                                                                     Sub-Premise of Premise=FIELD(No.)));
            Caption = 'Sub Premise Total L/S';
            Editable = false;
            FieldClass = FlowField;
        }
        field(41;"Sub Premise Total Non L/S";Decimal)
        {
            CalcFormula = Sum(Premise."Non Leasable/Salable Area" WHERE (Premise/Sub-Premise=FILTER(Sub-Premise),
                                                                         Sub-Premise of Premise=FIELD(No.)));
            Caption = 'Sub Premise Total Non L/S';
            Editable = false;
            FieldClass = FlowField;
        }
        field(42;"Sub Premise Total Area";Decimal)
        {
            Caption = 'Sub Premise Total Area';
            Editable = false;
        }
        field(43;"Pre-Booked";Boolean)
        {
            Editable = false;
        }
        field(44;"Allow Multiple Agreements";Boolean)
        {
            Editable = false;
        }
        field(45;"Pre-Booked Agreement No.";Code[20])
        {
        }
    }

    keys
    {
        key(Key1;"No.")
        {
            Clustered = true;
        }
        key(Key2;"Premise/Sub-Premise","Sub-Premise of Premise")
        {
        }
        key(Key3;"Client No.","No.")
        {
            SumIndexFields = "Leasable/Salable Area";
        }
        key(Key4;"Sub-Premise of Premise","Premise/Sub-Premise")
        {
            SumIndexFields = "Leasable/Salable Area","Non Leasable/Salable Area";
        }
        key(Key5;"Sub-Premise of Premise","Premise Status")
        {
        }
        key(Key6;"Floor No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AgreementPremiseRec: Record "Agreement Premise Relation";
    begin
        AgreementPremiseRec.RESET;
        AgreementPremiseRec.SETFILTER("Agreement No.",'<>%1','');
        AgreementPremiseRec.SETRANGE("Premise No.","No.");
        IF AgreementPremiseRec.FINDFIRST THEN
          ERROR(Text001,"No.","No.",AgreementPremiseRec."Agreement Type",AgreementPremiseRec."Agreement No.");
    end;

    trigger OnInsert()
    begin
        IF "No." = '' THEN BEGIN
          PremiseMgtSetup.GET;
          PremiseMgtSetup.TESTFIELD(Premise);
          NoSeriesMgt.InitSeries(PremiseMgtSetup.Premise,xRec."No. Series",0D,"No.","No. Series");
        END;
        "Premise Status":= 0;
        DimMgt.UpdateDefaultDim(
          DATABASE::Premise,"No.",
          "Global Dimension 1 Code","Global Dimension 2 Code");
        "Premise/Sub-Premise" := "Premise/Sub-Premise"::Premise;
        "Sub-Premise of Premise" := "No.";
    end;

    var
        DimMgt: Codeunit "408";
        PremiseMgtSetup: Record "Premise Management Setup";
        NoSeriesMgt: Codeunit "396";
        Premise: Record Premise;
        PostCode: Record "Post Code";
        Text001: Label 'You cannot delete Premise %1. Premise %2 is linked with Agreement %3 No. %4.';
        Text002: Label 'Premise No. %1 is already linked with Sub Premise No. %2 ';
        Text003: Label 'Client Type not defined for Client No. %1';
        Text33016808: Label 'Premise/SubPremise %1 exist with status = %2';
 
    procedure ValidateShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
        DimMgt.SaveDefaultDim(DATABASE::Premise,"No.",FieldNumber,ShortcutDimCode);
        MODIFY;
    end;
 
    procedure LookupShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber,ShortcutDimCode);
        DimMgt.SaveDefaultDim(DATABASE::Premise,"No.",FieldNumber,ShortcutDimCode);
    end;
 
    procedure AssistEdit(OldPremiseRec: Record Premise): Boolean
    var
        PremiseRec: Record Premise;
    begin
        WITH PremiseRec DO BEGIN
          PremiseRec := Rec;
          PremiseMgtSetup.GET;
          PremiseMgtSetup.TESTFIELD(Premise);
          IF NoSeriesMgt.SelectSeries(PremiseMgtSetup.Premise,OldPremiseRec."No. Series","No. Series") THEN BEGIN
            NoSeriesMgt.SetSeries("No.");
            Rec := PremiseRec;
            EXIT(TRUE);
          END;
        END;
    end;
 
    procedure ResetPremiseInfo()
    begin
        Address := '';
        Address2 := '';
        "Floor No." := '';
        "Post Code" := '';
        City := '';
        "Country Code" := '';
        "Region Code" := '';
        "Premise Group" := '';
        "Premise Sub Group" := '';
    end;
 
    procedure UpdateTotalSubPremiseArea()
    begin
        CALCFIELDS("Sub Premise Total L/S","Sub Premise Total Non L/S");
        "Sub Premise Total Area" := "Sub Premise Total L/S" + "Sub Premise Total Non L/S";
    end;
 
    procedure AllowMultipleAgreements()
    var
        PremiseRec: Record Premise;
    begin
        PremiseRec.GET("No.");
        PremiseRec.TESTFIELD("Allow Multiple Agreements",FALSE);
        CheckPremiseVacant(PremiseRec);

        PremiseRec."Allow Multiple Agreements" := TRUE;
        PremiseRec.MODIFY;
    end;
 
    procedure RemoveMultipleAgreements()
    var
        PremiseRec: Record Premise;
    begin
        PremiseRec.GET("No.");
        PremiseRec.TESTFIELD("Allow Multiple Agreements",TRUE);
        CheckPremiseVacant(PremiseRec);

        PremiseRec."Allow Multiple Agreements" := FALSE;
        PremiseRec.MODIFY;
    end;
 
    procedure CheckPremiseVacant(PremiseRec: Record Premise)
    var
        SubPremiseRec: Record Premise;
    begin
        PremiseRec.TESTFIELD(PremiseRec."Premise Status",PremiseRec."Premise Status"::Vacant);

        SubPremiseRec.RESET;
        SubPremiseRec.SETCURRENTKEY("Sub-Premise of Premise","Premise/Sub-Premise");
        SubPremiseRec.SETRANGE("Sub-Premise of Premise",PremiseRec."No.");
        SubPremiseRec.SETRANGE("Premise/Sub-Premise",SubPremiseRec."Premise/Sub-Premise"::"Sub-Premise");
        SubPremiseRec.SETFILTER("Premise Status",'<>%1',0);
        IF SubPremiseRec.FINDFIRST THEN
          ERROR(Text33016808,SubPremiseRec."No.",SubPremiseRec."Premise Status");
    end;
 
    procedure UpdateBlockedAgreement(PremiseNo: Code[20];IsBlocked: Boolean)
    var
        AgrmtPremiseRelation: Record "Agreement Premise Relation";
        AgrmtHdr: Record "Agreement Header";
        AgrmtLine: Record "Agreement Line";
    begin
        AgrmtPremiseRelation.RESET;
        AgrmtPremiseRelation.SETRANGE("Premise No.",PremiseNo);
        AgrmtPremiseRelation.SETFILTER("Agreement Status",'<>%1',AgrmtPremiseRelation."Agreement Status"::Closed);
        IF AgrmtPremiseRelation.FINDSET THEN BEGIN
          REPEAT
            AgrmtHdr.GET(AgrmtPremiseRelation."Agreement Type",AgrmtPremiseRelation."Agreement No.");
            IF AgrmtHdr."Agreement Status" IN [AgrmtHdr."Agreement Status"::New,AgrmtHdr."Agreement Status"::Active] THEN BEGIN
              AgrmtLine.RESET;
              AgrmtLine.SETRANGE("Agreement Type",AgrmtHdr."Agreement Type");
              AgrmtLine.SETRANGE("Agreement No.",AgrmtHdr."No.");
              AgrmtLine.SETRANGE("Premise No.",PremiseNo);
              IF AgrmtLine.FINDSET(FALSE,FALSE) THEN BEGIN
                REPEAT
                  AgrmtLine.VALIDATE("Premise Blocked",IsBlocked);
                  AgrmtLine.MODIFY;
                UNTIL AgrmtLine.NEXT = 0;
              END;
            END;
          UNTIL AgrmtPremiseRelation.NEXT = 0;
        END;
    end;
 
    procedure BlockSubPremises(IsBlocked: Boolean)
    var
        SubPremiseRec: Record Premise;
    begin
        SubPremiseRec.RESET;
        SubPremiseRec.SETCURRENTKEY("Sub-Premise of Premise","Premise/Sub-Premise");
        SubPremiseRec.SETRANGE("Sub-Premise of Premise","No.");
        SubPremiseRec.SETRANGE("Premise/Sub-Premise",SubPremiseRec."Premise/Sub-Premise"::"Sub-Premise");
        IF SubPremiseRec.FINDSET THEN BEGIN
          REPEAT
           SubPremiseRec.VALIDATE(Blocked,IsBlocked);
           SubPremiseRec.MODIFY;
           UpdateBlockedAgreement(SubPremiseRec."No.",IsBlocked);
          UNTIL SubPremiseRec.NEXT = 0;
        END;
    end;
}

