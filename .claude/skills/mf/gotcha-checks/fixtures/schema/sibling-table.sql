-- Synthetic file representing a sibling SP that creates the same object as a TABLE.
-- Used by collision.diff fixture: the diff converts ARCID_PROFILES to a VIEW
-- in another file, and the check script should detect this file as the conflict.
CREATE OR REPLACE TRANSIENT TABLE arcid_profiles AS
SELECT arcid, profile, segments
FROM tapad.public.arcid_profiles
WHERE silo = lower(current_database());
