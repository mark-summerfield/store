-- Copyright © 2025 Mark Summerfield. All Rights Reserved.

-- we don't need '.*' since hidden files are always ignored
INSERT INTO Ignores (pattern) VALUES ('*.a');
INSERT INTO Ignores (pattern) VALUES ('*.bak');
INSERT INTO Ignores (pattern) VALUES ('*.class');
INSERT INTO Ignores (pattern) VALUES ('*.dll');
INSERT INTO Ignores (pattern) VALUES ('*.exe');
INSERT INTO Ignores (pattern) VALUES ('*.jar');
INSERT INTO Ignores (pattern) VALUES ('*.jpeg');
INSERT INTO Ignores (pattern) VALUES ('*.jpg');
INSERT INTO Ignores (pattern) VALUES ('*.ld');
INSERT INTO Ignores (pattern) VALUES ('*.ldx');
INSERT INTO Ignores (pattern) VALUES ('*.li');
INSERT INTO Ignores (pattern) VALUES ('*.lix');
INSERT INTO Ignores (pattern) VALUES ('*.o');
INSERT INTO Ignores (pattern) VALUES ('*.obj');
INSERT INTO Ignores (pattern) VALUES ('*.png');
INSERT INTO Ignores (pattern) VALUES ('*.py[co]');
INSERT INTO Ignores (pattern) VALUES ('*.rs.bk');
INSERT INTO Ignores (pattern) VALUES ('*.so');
INSERT INTO Ignores (pattern) VALUES ('*.svg');
INSERT INTO Ignores (pattern) VALUES ('*.sw[nop]');
INSERT INTO Ignores (pattern) VALUES ('*.tmp');
INSERT INTO Ignores (pattern) VALUES ('*~');
INSERT INTO Ignores (pattern) VALUES ('[#]*#');
INSERT INTO Ignores (pattern) VALUES ('__pycache__');
INSERT INTO Ignores (pattern) VALUES ('louti[0-9]*');
INSERT INTO Ignores (pattern) VALUES ('moc_*.cpp');
INSERT INTO Ignores (pattern) VALUES ('qrc_*.cpp');
INSERT INTO Ignores (pattern) VALUES ('test*');
INSERT INTO Ignores (pattern) VALUES ('tmp/*');
INSERT INTO Ignores (pattern) VALUES ('ui_*.h');
INSERT INTO Ignores (pattern) VALUES ('zOld/*');
