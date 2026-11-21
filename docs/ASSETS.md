# Kostenlose Assets für Valora City

Diese Quellen sind für ein kommerzielles Spiel geeignet. Lies vor dem Herunterladen trotzdem die Lizenz auf der jeweiligen Seite.
Grundregel: Keine Markenlogos, keine echten Autonamen und keine Figuren oder Namen aus anderen Spielen verwenden.

## Quellen

| Quelle | Was | Lizenz | Hinweis |
|---|---|---|---|
| [Poly Haven](https://polyhaven.com) | HDRI-Himmel, PBR-Texturen, Modelle | CC0 | Ohne Namensnennung nutzbar. Texturen in 1K/2K reichen für den Browser. |
| [ambientCG](https://ambientcg.com) | PBR-Materialien (Asphalt, Beton, Marmor, Holz, Lack) | CC0 | Paket „1K-JPG“ nehmen, darin Color, NormalGL, Roughness, Metalness, AO. |
| [Quaternius](https://quaternius.com) | Low-Poly-Figuren mit Rig und Animationen, Fahrzeuge, Stadtobjekte | CC0 | Gut für NPCs und als Basis für die Hauptfigur. |
| [Kenney](https://kenney.nl) | Stadt-Bausätze, Autos, Möbel, Sounds | CC0 | Sehr leicht, gut fürs Handy. |
| [Sketchfab](https://sketchfab.com) | Detaillierte Modelle | je Modell: nur CC0 oder CC-BY | Filter „Downloadable“ und Lizenz setzen. Bei CC-BY den Autor im Abspann nennen. Keine Modelle mit echten Marken. |
| [Mixamo](https://www.mixamo.com) | Rigs und Animationen (Gehen, Rennen, Springen, Zielen, Ein-/Aussteigen) | Adobe-Konto, lizenzfrei für eigene Projekte | Animationen im Spiel nutzen ist erlaubt. Die Rohdateien nicht weiterverteilen. |
| [Freesound](https://freesound.org) | Motorsounds, Stadtgeräusche | je Sound: CC0 oder CC-BY | Bei CC-BY den Urheber nennen. |

## Dateien vorbereiten (Größe und Performance)

1. Modelle als **.glb** exportieren (Blender: Datei → Exportieren → glTF 2.0, Format „glb“).
2. Verkleinern, zum Beispiel mit glTF-Transform (Node.js):
   `npx @gltf-transform/cli optimize eingabe.glb ausgabe.glb --texture-compress webp`
   Das fasst Daten zusammen, komprimiert Geometrie und wandelt Texturen in WebP um. Die genauen Optionen zeigt `npx @gltf-transform/cli optimize --help`.
3. Texturen höchstens 1024×1024 für Straßen und Gebäude, 2048×2048 nur für die Hauptfigur und das eigene Auto.
4. Für Detailstufen (LOD) pro Modell zwei Versionen exportieren (volle und vereinfachte Geometrie, z. B. Blender-Modifier „Decimate“ auf 25 %).

## Einbinden in Valora City (Three.js r128)

Die Dateien kommen als Begleitdateien neben `index.html`, z. B. `assets/textures/asphalt/…` und `assets/models/held.glb`.

### 1. Loader-Skript laden (nach `three.min.js`)
```html
<script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js"></script>
```

### 2. PBR-Textur-Set laden (z. B. ambientCG „Asphalt“)
```js
const texLoader = new THREE.TextureLoader();
function loadPBR(pfad, wiederholung) {
  const t = (datei, srgb) => {
    const tex = texLoader.load(pfad + datei);
    tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(wiederholung, wiederholung);
    tex.anisotropy = renderer.capabilities.getMaxAnisotropy();
    if (srgb) tex.encoding = THREE.sRGBEncoding; // nur die Farbtextur ist sRGB
    return tex;
  };
  return new THREE.MeshStandardMaterial({
    map: t('Color.jpg', true),
    normalMap: t('NormalGL.jpg'),      // ambientCG liefert NormalGL für OpenGL/Three.js
    roughnessMap: t('Roughness.jpg'),
    aoMap: t('AmbientOcclusion.jpg'),  // braucht ein zweites UV-Set (uv2)
    roughness: 1, metalness: 0
  });
}
// Beispiel: asphaltMat im Spiel ersetzen
// const asphaltMat = loadPBR('assets/textures/asphalt/Asphalt_', 86);
```

### 3. Geriggte Figur mit Animationen laden
```js
const gltfLoader = new THREE.GLTFLoader();
gltfLoader.load('assets/models/held.glb', (gltf) => {
  const held = gltf.scene;
  held.traverse(o => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });
  scene.add(held);
  const mixer = new THREE.AnimationMixer(held);
  const clip = name => THREE.AnimationClip.findByName(gltf.animations, name);
  const idle = mixer.clipAction(clip('Idle'));
  const walk = mixer.clipAction(clip('Walk'));
  idle.play();
  // Weicher Übergang, z. B. wenn der Spieler losläuft:
  // idle.crossFadeTo(walk.reset().play(), 0.25, false);
  // Im Spiel-Loop: mixer.update(dt);
});
```

### 4. HDRI-Himmel (Poly Haven, .hdr)
Dafür kommt `examples/js/loaders/RGBELoader.js` dazu. Die HDRI wird mit `PMREMGenerator` umgewandelt und als `scene.environment` gesetzt. Für Tag und Nacht braucht man mehrere HDRIs (z. B. eine für Mittag, eine für Sonnenuntergang, eine für Nacht), zwischen denen das Spiel je nach Uhrzeit wechselt. Bis dahin nutzt Valora City eine erzeugte Umgebungs-Map, deren Stärke sich mit der Tageszeit ändert.

## Was das Spiel ohne Asset-Dateien schon kann (Schritt 1)
- Grafikstufen Niedrig, Mittel und Hoch, umschaltbar mit **G** oder dem Button „⚙ GRAFIK“
- Hoch: Ambient Occlusion (SSAO), SMAA-Kantenglättung, Schattenkarte 4096
- Mittel und Niedrig: FXAA-Kantenglättung, kleinere Schattenkarten
- Spiegelungen auf Glas, Lack, Pfützen und Metall, deren Stärke sich mit Tageszeit und Wetter ändert
- Autolack mit Klarlackschicht (ab Mittel)
- Schatten nur für Autos und Personen in der Nähe (Detailstufen)
- Automatische Auflösung: Fällt die Bildrate unter 34 FPS, rendert das Spiel mit geringerer Auflösung und erhöht sie wieder, sobald genug Leistung da ist
- FPS-Anzeige im Startmenü einschaltbar
