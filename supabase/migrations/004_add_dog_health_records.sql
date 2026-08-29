CREATE TABLE IF NOT EXISTS treatfeedtails.sterilization_vaccination_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dog_id UUID NOT NULL UNIQUE REFERENCES treatfeedtails.primary_dog_details (id)
        ON DELETE CASCADE,
    sterilization_status TEXT NOT NULL CHECK (sterilization_status IN ('yes', 'no')),
    vaccinated BOOLEAN NOT NULL DEFAULT FALSE,
    rabies BOOLEAN NOT NULL DEFAULT FALSE,
    nine_in_one BOOLEAN NOT NULL DEFAULT FALSE,
    vaccination_date TIMESTAMPTZ,
    CHECK (
        (vaccinated AND (rabies OR nine_in_one) AND vaccination_date IS NOT NULL)
        OR (NOT vaccinated AND NOT rabies AND NOT nine_in_one AND vaccination_date IS NULL)
    )
);

GRANT SELECT, INSERT, UPDATE, DELETE
    ON treatfeedtails.sterilization_vaccination_details TO anon, authenticated;

ALTER TABLE treatfeedtails.sterilization_vaccination_details ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public sterilization and vaccination access"
    ON treatfeedtails.sterilization_vaccination_details
    FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);