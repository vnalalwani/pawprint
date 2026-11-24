ALTER TABLE treatfeedtails.sterilization_vaccination_details
    ADD COLUMN IF NOT EXISTS sent_for_sterilization BOOLEAN NOT NULL DEFAULT FALSE;
