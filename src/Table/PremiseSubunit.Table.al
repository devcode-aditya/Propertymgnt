table 33016819 "Premise Subunit"
{
    Caption = 'Premise Subunit';
    LookupFormID = Form33016825;

    fields
    {
        field(1; "Premise Code"; Code[20])
        {
            NotBlank = true;
            TableRelation = Premise.No.;

            trigger OnValidate()
            begin
                IF "Premise Code" <> xRec."Premise Code" THEN
                  "Subpremise of Premise" := '';
            end;
        }
        field(2;"Code";Code[20])
        {
            NotBlank = true;
        }
        field(3;"Subunit Type";Code[20])
        {
            TableRelation = "Premise Sub Unit Type".Code;
        }
        field(4;"Area";Integer)
        {
            MinValue = 0;
        }
        field(5;"Area UOM";Code[20])
        {
            TableRelation = "Unit of Measure".Code;
        }
        field(6;Description;Text[30])
        {
        }
        field(7;Comment;Boolean)
        {
        }
        field(8;"Subpremise of Premise";Code[20])
        {

            trigger OnLookup()
            var
                PremiseMaster: Record Premise;
                PremiseRec: Record Premise;
                PremiseFrm: Form "33016803";
            begin
                IF PremiseMaster.GET("Premise Code") THEN BEGIN
                  PremiseMaster.TESTFIELD("Sub-Premise of Premise");
                  IF PremiseRec.GET(PremiseMaster."Sub-Premise of Premise") THEN
                    PremiseRec.MARK(TRUE);

                  PremiseRec.MARKEDONLY(TRUE);
                  CLEAR(PremiseFrm);
                  PremiseFrm.SETTABLEVIEW(PremiseRec);
                  PremiseFrm.SETRECORD(PremiseRec);
                  PremiseFrm.LOOKUPMODE(TRUE);
                  IF PremiseFrm.RUNMODAL = ACTION::LookupOK THEN BEGIN
                    PremiseFrm.GETRECORD(PremiseRec);
                    "Subpremise of Premise" := PremiseRec."No.";
                  END;
                END;
            end;

            trigger OnValidate()
            var
                PremiseRec: Record Premise;
            begin
                IF "Subpremise of Premise" <> '' THEN
                  PremiseRec.GET("Subpremise of Premise");

                IF (PremiseRec.GET("Premise Code")) AND ("Subpremise of Premise" <> '') THEN BEGIN
                  IF PremiseRec."Sub-Premise of Premise" <> "Subpremise of Premise" THEN
                    ERROR(Text001,PremiseRec."Sub-Premise of Premise");
                END;
            end;
        }
    }

    keys
    {
        key(Key1;"Premise Code","Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'Sub-Premise of Premise value must be %1.';
}

