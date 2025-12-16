table 33016845 "Client Profile Answer"
{
    Caption = 'Client Profile Answer';
    DrillDownFormID = Form5115;

    fields
    {
        field(1; "Client No."; Code[20])
        {
            Caption = 'Contact No.';
            NotBlank = true;
            TableRelation = Customer;

            trigger OnValidate()
            var
                Cont: Record Contact;
            begin
            end;
        }
        field(3; "Profile Questionnaire Code"; Code[10])
        {
            Caption = 'Profile Questionnaire Code';
            NotBlank = true;
            TableRelation = "Profile Questionnaire Header";

            trigger OnValidate()
            var
                ProfileQuestnHeader: Record "Profile Questionnaire Header";
            begin
                ProfileQuestnHeader.GET("Profile Questionnaire Code");
                "Profile Questionnaire Priority" := ProfileQuestnHeader.Priority;
            end;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            TableRelation = "Profile Questionnaire Line"."Line No." WHERE(Profile Questionnaire Code=FIELD(Profile Questionnaire Code),
                                                                           Type=CONST(Answer));

            trigger OnValidate()
            var
                ProfileQuestnLine: Record "Profile Questionnaire Line";
            begin
                ProfileQuestnLine.GET("Profile Questionnaire Code", "Line No.");
                "Answer Priority" := ProfileQuestnLine.Priority;
            end;
        }
        field(5; Answer; Text[50])
        {
            CalcFormula = Lookup("Profile Questionnaire Line".Description WHERE(Profile Questionnaire Code=FIELD(Profile Questionnaire Code),
                                                                                 Line No.=FIELD(Line No.)));
            Caption = 'Answer';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7;"Client Name";Text[50])
        {
            CalcFormula = Lookup(Customer.Name WHERE (No.=FIELD(Client No.)));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8;"Profile Questionnaire Priority";Option)
        {
            Caption = 'Profile Questionnaire Priority';
            Editable = false;
            OptionCaption = 'Very Low,Low,Normal,High,Very High';
            OptionMembers = "Very Low",Low,Normal,High,"Very High";
        }
        field(9;"Answer Priority";Option)
        {
            Caption = 'Answer Priority';
            OptionCaption = 'Very Low (Hidden),Low,Normal,High,Very High';
            OptionMembers = "Very Low (Hidden)",Low,Normal,High,"Very High";
        }
        field(10;"Last Date Updated";Date)
        {
            Caption = 'Last Date Updated';
        }
        field(11;"Questions Answered (%)";Decimal)
        {
            BlankZero = true;
            Caption = 'Questions Answered (%)';
            DecimalPlaces = 0:0;
        }
        field(16;"Question Line No.";Integer)
        {
            Caption = 'Question Line No.';
        }
        field(17;"Answer Type";Option)
        {
            Caption = 'Answer Type';
            OptionCaption = 'Check,Text,Number,Boolean,Date';
            OptionMembers = Check,Text,Number,Boolean,Date;
        }
        field(18;"Min. Value";Decimal)
        {
            Caption = 'Min. Value';
        }
        field(19;"Max Value";Decimal)
        {
            Caption = 'Max Value';
        }
        field(20;AnswerCopy;Text[250])
        {
            Caption = 'AnswerCopy';

            trigger OnValidate()
            var
                ldteDate: Date;
                LdecDec: Decimal;
                LblnBool: Boolean;
            begin
                IF (AnswerCopy = '') OR ("Answer Type" = "Answer Type"::Check) THEN
                  EXIT;
                CASE "Answer Type" OF
                  "Answer Type"::Number :
                    IF NOT EVALUATE(LdecDec,AnswerCopy) THEN
                      ERROR(Text002,AnswerCopy)
                    ELSE IF (("Min. Value" <> 0) AND (LdecDec < "Min. Value")) OR
                      (("Max Value" <> 0) AND (LdecDec > "Max Value")) THEN
                      ERROR(Text005,AnswerCopy,"Min. Value","Max Value")
                    ELSE
                      AnswerCopy := FORMAT(LdecDec);
                  "Answer Type"::Date :
                    IF NOT EVALUATE(ldteDate,AnswerCopy) THEN
                      ERROR(Text003,AnswerCopy)
                    ELSE
                      AnswerCopy := FORMAT(ldteDate);
                  "Answer Type"::Boolean :
                    IF NOT EVALUATE(LblnBool,AnswerCopy) THEN
                      ERROR(Text004)
                    ELSE
                      AnswerCopy := FORMAT(LblnBool);
                END;
            end;
        }
        field(21;Comment;Boolean)
        {
        }
    }

    keys
    {
        key(Key1;"Client No.","Profile Questionnaire Code","Line No.")
        {
            Clustered = true;
        }
        key(Key2;"Client No.","Answer Priority","Profile Questionnaire Priority")
        {
        }
        key(Key3;"Profile Questionnaire Code","Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Rating: Record Rating;
        ProfileQuestnLine: Record "Profile Questionnaire Line";
    begin
    end;

    trigger OnInsert()
    var
        ContProfileAnswer: Record "Contact Profile Answer";
        ProfileQuestnLine: Record "Profile Questionnaire Line";
        ProfileQuestnLine2: Record "Profile Questionnaire Line";
        ProfileQuestnLine3: Record "Profile Questionnaire Line";
        Cont: Record Contact;
        Client: Record Customer;
        ClientProfileAnswer: Record "Client Profile Answer";
    begin
        ProfileQuestnLine.GET("Profile Questionnaire Code","Line No.");
        ProfileQuestnLine.TESTFIELD(Type,ProfileQuestnLine.Type::Answer);
        ProfileQuestnLine2.GET("Profile Questionnaire Code",QuestionLineNo);
        ProfileQuestnLine2.TESTFIELD("Auto Contact Classification",FALSE);
        IF NOT ProfileQuestnLine2."Multiple Answers" THEN BEGIN
          ClientProfileAnswer.RESET;
          ProfileQuestnLine3.RESET;
          ProfileQuestnLine3.SETRANGE("Profile Questionnaire Code","Profile Questionnaire Code");
          ProfileQuestnLine3.SETRANGE(Type,ProfileQuestnLine3.Type::Question);
          ProfileQuestnLine3.SETFILTER("Line No.", '>%1',ProfileQuestnLine2."Line No.");
          IF ProfileQuestnLine3.FIND('-') THEN
            ClientProfileAnswer.SETRANGE("Line No.",ProfileQuestnLine2."Line No.",ProfileQuestnLine3."Line No.")
          ELSE
            ClientProfileAnswer.SETFILTER("Line No.", '>%1',ProfileQuestnLine2."Line No.");
          ClientProfileAnswer.SETRANGE("Client No.","Client No.");
          ClientProfileAnswer.SETRANGE("Profile Questionnaire Code","Profile Questionnaire Code");
          IF ClientProfileAnswer.FIND('-') THEN
            ERROR(Text001,ProfileQuestnLine2.FIELDCAPTION("Multiple Answers"));
        END;

        "Question Line No." := QuestionLineNo();
        CALCFIELDS(Answer);
        AnswerCopy := FORMAT(Answer);
    end;

    var
        Text001: Label 'This Question does not allow %1.';
        Text002: Label '%1 is not a numerical value';
        Text003: Label '%1 is not a valid date';
        Text004: Label 'Answer can only be YES or NO';
        Text005: Label '%1 is not allowed (min %2 -  max %3)';
        UpdateContactClassification: Report "5199";

    procedure Question(): Text[50]
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
    begin
        IF ProfileQuestnLine.GET("Profile Questionnaire Code", QuestionLineNo) THEN
            EXIT(ProfileQuestnLine.Description)
    end;

    procedure QuestionLineNo(): Integer
    var
        ProfileQuestnLine: Record "Profile Questionnaire Line";
    begin
        WITH ProfileQuestnLine DO BEGIN
            RESET;
            SETRANGE("Profile Questionnaire Code", Rec."Profile Questionnaire Code");
            SETFILTER("Line No.", '<%1', Rec."Line No.");
            SETRANGE(Type, Type::Question);
            IF FIND('+') THEN
                EXIT("Line No.")
        END;
    end;
}

