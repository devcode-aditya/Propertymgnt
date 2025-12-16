table 33016846 "Premise Insurance"
{
    Caption = 'Premise Insurance';
    DrillDownFormID = Form33016871;
    LookupFormID = Form33016871;

    fields
    {
        field(1; "Insurance Code"; Code[20])
        {
        }
        field(2; "Insurance Description"; Text[50])
        {
        }
        field(3; "Insurance Type"; Option)
        {
            OptionCaption = 'General,Other';
            OptionMembers = General,Other;
        }
        field(4; "Issue Date"; Date)
        {

            trigger OnValidate()
            begin
                IF "Issue Date" <> 0D THEN
                    "Expiry Date" := CALCDATE(Period, "Issue Date");
            end;
        }
        field(5; Period; DateFormula)
        {

            trigger OnValidate()
            begin
                IF "Issue Date" <> 0D THEN
                    "Expiry Date" := CALCDATE(Period, "Issue Date");
            end;
        }
        field(6; "Expiry Date"; Date)
        {
        }
        field(7; "Insurance Value"; Decimal)
        {

            trigger OnValidate()
            begin
                ValidateInsuranceAmount;
            end;
        }
        field(8; "Premium Amount"; Decimal)
        {

            trigger OnValidate()
            begin
                ValidateInsuranceAmount;
            end;
        }
        field(9; "Payment Method"; Code[20])
        {
            TableRelation = "Payment Method".Code;
        }
        field(10; "Payment Period"; Option)
        {
            OptionCaption = 'Monthly,Quarterly,Bi-Annually,Annually';
            OptionMembers = Monthly,Quarterly,"Bi-Annually",Annually;
        }
        field(11; "Insurance Authority"; Code[20])
        {
            TableRelation = Vendor.No.;

            trigger OnValidate()
            var
                InsuranceScheduleRec: Record "Premise Insurance Schedule";
            begin
                IF "Insurance Authority" <> xRec."Insurance Authority" THEN BEGIN
                    InsuranceScheduleRec.RESET;
                    InsuranceScheduleRec.SETRANGE("Insurance Code", "Insurance Code");
                    IF InsuranceScheduleRec.FINDFIRST THEN BEGIN
                        IF CONFIRM(Text002, FALSE, "Insurance Code") THEN
                            REPEAT
                                InsuranceScheduleRec."Insurance Authority" := "Insurance Authority";
                                InsuranceScheduleRec.MODIFY;
                            UNTIL InsuranceScheduleRec.NEXT = 0;
                    END;
                END;
            end;
        }
        field(12; "Document Attachment"; Boolean)
        {
        }
        field(13; "Next Premium Payment Date"; Date)
        {
        }
        field(14; "No. Series"; Code[10])
        {
            TableRelation = "No. Series".Code;
        }
        field(15; Comment; Boolean)
        {
            CalcFormula = Exist("Premise Comment" WHERE(Table Name=FILTER(Insurance),
                                                         No.=FIELD(Insurance Code)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(16;"Premise No.";Code[20])
        {
            TableRelation = Premise;

            trigger OnValidate()
            var
                InsuranceScheduleRec: Record "Premise Insurance Schedule";
            begin
                IF "Premise No." <> xRec."Premise No." THEN BEGIN
                  InsuranceScheduleRec.RESET;
                  InsuranceScheduleRec.SETRANGE("Insurance Code","Insurance Code");
                  IF InsuranceScheduleRec.FINDFIRST THEN BEGIN
                    IF CONFIRM(Text003,FALSE,"Premise No.") THEN
                      REPEAT
                        InsuranceScheduleRec."Premise No." := "Premise No.";
                        InsuranceScheduleRec.MODIFY;
                      UNTIL InsuranceScheduleRec.NEXT = 0;
                  END;
                END;
            end;
        }
    }

    keys
    {
        key(Key1;"Insurance Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        IF "Insurance Code" = '' THEN BEGIN
          PremiseMgtSetup.GET;
          PremiseMgtSetup.TESTFIELD(Insurance);
          NoSeriesMgt.InitSeries(PremiseMgtSetup.Insurance,xRec."No. Series",0D,"Insurance Code","No. Series");
        END;
    end;

    var
        PremiseMgtSetup: Record "Premise Management Setup";
        NoSeriesMgt: Codeunit "396";
        Text001: Label 'Premium Amount %1 should not be greater than Insurance Amount %2';
        Text002: Label 'Insurance Schedule Entries exists for Insurance %1. Do you want to change the Insurance Authority?';
        Text003: Label 'Insurance Schedule Entries exists for Insurance %1. Do you want to change the Premise No.?';
 
    procedure AssistEdit(OldInsuranceRec: Record "Premise Insurance"): Boolean
    var
        PremiseInsuranceRec: Record "Premise Insurance";
    begin
        WITH PremiseInsuranceRec DO BEGIN
          PremiseInsuranceRec := Rec;
          PremiseMgtSetup.GET;
          PremiseMgtSetup.TESTFIELD(Insurance);
          IF NoSeriesMgt.SelectSeries(PremiseMgtSetup.Insurance,OldInsuranceRec."No. Series","No. Series") THEN BEGIN
            NoSeriesMgt.SetSeries("Insurance Code");
            Rec := PremiseInsuranceRec;
            EXIT(TRUE);
          END;
        END;
    end;
 
    procedure ValidateInsuranceAmount()
    begin
        IF "Insurance Value" <> 0 THEN BEGIN
          IF "Insurance Value" < "Premium Amount" THEN
            ERROR(Text001,"Premium Amount","Insurance Value");
        END ELSE
          "Premium Amount" := 0;
    end;
}

