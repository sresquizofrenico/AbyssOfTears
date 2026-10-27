import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from tools.publish_release import prepare, publish

class PublicReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / 'data').mkdir()
        self.config = {'version': 2, 'sample': 'original'}
        self.score = {'version': 1, 'tracks': [{'id': 'menu', 'path': 'res://assets/audio/music/menu.ogg'}]}
        (self.root / 'data/soundtrack.json').write_text(json.dumps(self.score))
        for name in ['balance.json', 'relics_expansion.json', 'archaeology.json']:
            (self.root / 'data' / name).write_text(json.dumps(self.config))
        self.apk = self.root / 'game.apk'
        with zipfile.ZipFile(self.apk, 'w') as archive:
            archive.writestr('AndroidManifest.xml', b'test-manifest')
            archive.writestr('lib/arm64-v8a/libgodot_android.so', b'test-engine')
            archive.writestr('assets/data/soundtrack.json', json.dumps(self.score))
            from tools.verify_audio_assets import EFFECTS
            for path in ['assets/audio/music/menu.ogg', *[f'assets/audio/sfx/{name}.wav' for name in EFFECTS]]:
                archive.writestr('assets/' + path + '.import', '[remap]\npath="res://.godot/imported/test-audio.sample"\n')
            archive.writestr('assets/.godot/imported/test-audio.sample', b'unit-test-import-resource')
            for name in ['balance.json', 'relics_expansion.json', 'archaeology.json']:
                archive.writestr('assets/data/' + name, json.dumps(self.config))
        self.report = self.root / 'report.json'
        self.report.write_text(json.dumps({'version':'0.9.1', 'apk_bytes':self.apk.stat().st_size}))
    def tearDown(self):
        self.temp.cleanup()
    def test_exact_artifact_and_checksum(self):
        version, digest, assets = prepare(self.apk,self.report,self.root,'v0.9.1-public',self.root/'out')
        self.assertEqual(version,'0.9.1')
        self.assertEqual(assets[0].read_bytes(),self.apk.read_bytes())
        self.assertEqual(digest,hashlib.sha256(self.apk.read_bytes()).hexdigest())
        self.assertEqual(assets[1].read_text(),digest+'  AbyssOfTears-Android.apk\n')
    def test_invalid_version_rejected(self):
        self.report.write_text(json.dumps({"version":"../unsafe", "apk_bytes":self.apk.stat().st_size}))
        with self.assertRaises(ValueError): prepare(self.apk,self.report,self.root,"v../unsafe-public",self.root/"out")
    def test_changed_score_registry_rejected(self):
        (self.root/'data/soundtrack.json').write_text('{"changed":true}')
        with self.assertRaisesRegex(ValueError, 'soundtrack registry'):
            prepare(self.apk,self.report,self.root,'v0.9.1-public',self.root/'out')
    def rewrite_apk(self, old, new=None):
        with zipfile.ZipFile(self.apk) as archive:
            entries = {name: archive.read(name) for name in archive.namelist()}
        if new is None: entries.pop(old)
        else: entries[old] = new
        with zipfile.ZipFile(self.apk, 'w') as archive:
            for name, value in entries.items(): archive.writestr(name, value)
        self.report.write_text(json.dumps({'version':'0.9.1','apk_bytes':self.apk.stat().st_size}))
    def test_missing_audio_resource_rejected(self):
        self.rewrite_apk('assets/.godot/imported/test-audio.sample')
        with self.assertRaises(KeyError): prepare(self.apk,self.report,self.root,'v0.9.1-public',self.root/'out')
    def test_empty_audio_resource_rejected(self):
        self.rewrite_apk('assets/.godot/imported/test-audio.sample', b'')
        with self.assertRaisesRegex(ValueError, 'Empty exported sound'):
            prepare(self.apk,self.report,self.root,'v0.9.1-public',self.root/'out')
    def test_audio_mapping_cannot_escape_resource_directory(self):
        self.rewrite_apk('assets/assets/audio/music/menu.ogg.import', b'path="res://.godot/imported/../../../other"')
        with self.assertRaisesRegex(ValueError, 'Invalid exported sound import'):
            prepare(self.apk,self.report,self.root,'v0.9.1-public',self.root/'out')
    def test_tag_must_match_export(self):
        with self.assertRaises(ValueError): prepare(self.apk,self.report,self.root,'v0.9.2-public',self.root/'out')
    def test_size_mismatch_rejected(self):
        self.report.write_text('{"version":"0.9.1","apk_bytes":4}')
        with self.assertRaises(ValueError): prepare(self.apk,self.report,self.root,'v0.9.1-public',self.root/'out')
    def test_source_mismatch_rejected(self):
        (self.root/'data'/'balance.json').write_text('{"different":true}')
        with self.assertRaises(ValueError): prepare(self.apk,self.report,self.root,'v0.9.1-public',self.root/'out')
    def test_archaeology_source_mismatch_rejected(self):
        (self.root/'data'/'archaeology.json').write_text('{"different":true}')
        with self.assertRaisesRegex(ValueError,'archaeology.json'):
            prepare(self.apk,self.report,self.root,'v0.9.1-public',self.root/'out')
    def test_invalid_zip_rejected(self):
        self.apk.write_bytes(b'not an apk')
        self.report.write_text(json.dumps({'version':'0.9.1','apk_bytes':self.apk.stat().st_size}))
        with self.assertRaises(zipfile.BadZipFile): prepare(self.apk,self.report,self.root,'v0.9.1-public',self.root/'out')
    def test_published_asset_never_overwritten(self):
        from subprocess import CompletedProcess
        with patch('tools.publish_release.gh',return_value=CompletedProcess([],0,'{"isDraft":false,"assets":[],"url":"example"}','')) as call:
            with self.assertRaisesRegex(RuntimeError,'immutable'):
                publish('owner/repo','v0.9.1-public','0.9.1','digest',[],self.root/'notes')
            self.assertEqual(call.call_count,1)
    def test_upload_mismatch_stays_draft(self):
        from subprocess import CompletedProcess
        asset=self.root/'asset.apk'
        asset.write_bytes(b'apk')
        response=CompletedProcess([],0,'{"isDraft":true,"assets":[],"url":"example"}','')
        with patch('tools.publish_release.gh',return_value=response) as call:
            with self.assertRaisesRegex(RuntimeError,'missing or wrong size'):
                publish('owner/repo','v0.9.1-public','0.9.1','digest',[asset],self.root/'notes')
            self.assertFalse(any('edit' in args.args for args in call.call_args_list))
    def test_failed_remote_download_never_publishes(self):
        from subprocess import CompletedProcess
        asset=self.root/'asset.apk'
        asset.write_bytes(b'apk')
        def invoke(*args,**kwargs):
            if 'download' in args: raise RuntimeError('network failure')
            return CompletedProcess([],0,'{"isDraft":true,"assets":[{"name":"asset.apk","size":3}],"url":"example"}','')
        with patch('tools.publish_release.gh',side_effect=invoke) as call:
            with self.assertRaisesRegex(RuntimeError,'network failure'):
                publish('owner/repo','v0.9.1-public','0.9.1','digest',[asset],self.root/'notes')
            self.assertFalse(any('edit' in args.args for args in call.call_args_list))

if __name__ == '__main__': unittest.main()
