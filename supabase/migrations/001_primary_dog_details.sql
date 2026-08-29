CREATE SCHEMA IF NOT EXISTS treatfeedtails;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO storage.buckets (id, name, public)
VALUES ('furryfriends', 'furryfriends', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage' AND tablename = 'objects'
          AND policyname = 'public dog photo access'
    ) THEN
        CREATE POLICY "public dog photo access"
            ON storage.objects
            FOR ALL
            TO anon, authenticated
            USING (bucket_id = 'furryfriends')
            WITH CHECK (bucket_id = 'furryfriends');
    END IF;
END
$$;

CREATE SEQUENCE IF NOT EXISTS treatfeedtails.dog_tag_sequence
    START WITH 1
    INCREMENT BY 1;

CREATE OR REPLACE FUNCTION treatfeedtails.generate_dog_tag_id()
RETURNS TEXT
LANGUAGE plpgsql
VOLATILE
AS $$
BEGIN
    RETURN 'TFT-' || LPAD(
        nextval('treatfeedtails.dog_tag_sequence')::TEXT,
        6,
        '0'
    );
END;
$$;

CREATE TABLE IF NOT EXISTS treatfeedtails.primary_dog_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    tag_id TEXT UNIQUE NOT NULL
        DEFAULT treatfeedtails.generate_dog_tag_id(),

    animal_category TEXT NOT NULL,

    photo_path TEXT,

    name TEXT,
    gender TEXT,
    age INTEGER,
    color TEXT,
    breed TEXT,

    identifying_marks TEXT,
    notes TEXT,

    address TEXT,
    area TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,

    created_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    added_by TEXT,

    updated_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by TEXT
);

CREATE INDEX IF NOT EXISTS primary_dog_details_area_idx
    ON treatfeedtails.primary_dog_details (area);

CREATE INDEX IF NOT EXISTS primary_dog_details_updated_date_idx
    ON treatfeedtails.primary_dog_details (updated_date DESC);

GRANT USAGE ON SCHEMA treatfeedtails TO anon, authenticated;
GRANT USAGE ON SEQUENCE treatfeedtails.dog_tag_sequence
    TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
    ON treatfeedtails.primary_dog_details TO anon, authenticated;

ALTER TABLE treatfeedtails.primary_dog_details ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'treatfeedtails'
          AND tablename = 'primary_dog_details'
          AND policyname = 'public dog record access'
    ) THEN
        CREATE POLICY "public dog record access"
            ON treatfeedtails.primary_dog_details
            FOR ALL
            TO anon, authenticated
            USING (true)
            WITH CHECK (true);
    END IF;
END
$$;