CREATE TRIGGER InsertUniqueTag BEFORE INSERT ON Generations FOR EACH ROW
    WHEN EXISTS (SELECT TRUE FROM Generations
                    WHERE NEW.tag IS NOT NULL AND
                          NEW.tag != '' AND Generations.tag = NEW.tag)
        BEGIN
            SELECT RAISE(ABORT, 'every tag must be unique');
        END;
    
CREATE TRIGGER UpdateUniqueTag BEFORE UPDATE ON Generations FOR EACH ROW
    WHEN EXISTS (SELECT TRUE FROM Generations
                    WHERE NEW.tag IS NOT NULL AND
                          NEW.tag != '' AND Generations.tag = NEW.tag)
        BEGIN
            SELECT RAISE(ABORT, 'every tag must be unique');
        END;

PRAGMA USER_VERSION = 3;
