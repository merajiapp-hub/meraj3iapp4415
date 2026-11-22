/**
 * محاكاة ثلاثية الأبعاد تفاعلية: تحضير محلول والذوبان والتخفيف (Dissolution & Dilution)
 * منصة مراجعي التعليمية MERAJ3I - 3D Virtual Lab
 */

(function () {
  'use strict';

  const MOLAR_MASS = 249.68; // CuSO4·5H2O g/mol
  const VOL_0 = 0.100; // 100 mL = 0.1 L
  const DILUTION_FACTOR = 5;

  let state = {
    mass: 5.0,
    isDissolved: false,
    isDiluted: false,
    step: 1,
  };

  const DOM = {
    inputMass: document.getElementById('input-mass'),
    sliderMassVal: document.getElementById('slider-mass-val'),
    calcMass: document.getElementById('calc-mass'),
    calcMoles: document.getElementById('calc-moles'),
    calcVol: document.getElementById('calc-vol'),
    calcC0: document.getElementById('calc-c0'),
    calcC1: document.getElementById('calc-c1'),
    dilutionRow: document.getElementById('dilution-row'),
    stepBadge: document.getElementById('step-badge'),
    stepText: document.getElementById('step-text'),
    btnDissolve: document.getElementById('btn-dissolve'),
    btnDilute: document.getElementById('btn-dilute'),
    btnConclusion: document.getElementById('btn-conclusion'),
    btnReset: document.getElementById('btn-reset'),
    modal: document.getElementById('observation-modal'),
    modalCloseBtn: document.getElementById('modal-close-btn'),
  };

  // Three.js
  let scene, camera, renderer;
  let flask1Group, flask2Group, crystalGroup;
  let liquid1Mesh, liquid2Mesh, stirrerMesh;
  let isDragging = false, prevMousePos = { x: 0, y: 0 };
  let sceneRotationY = 0;

  function initThree() {
    const container = document.getElementById('canvas-container');
    const width = container.clientWidth || window.innerWidth;
    const height = container.clientHeight || window.innerHeight;

    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x08111e);
    scene.fog = new THREE.FogExp2(0x08111e, 0.04);

    camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 100);
    camera.position.set(0, 3.5, 8.5);
    camera.lookAt(0, 1.2, 0);

    renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.shadowMap.enabled = true;
    container.appendChild(renderer.domElement);

    // Lights
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.7);
    scene.add(ambientLight);

    const dirLight = new THREE.DirectionalLight(0xffffff, 0.9);
    dirLight.position.set(5, 12, 8);
    dirLight.castShadow = true;
    scene.add(dirLight);

    const blueLight = new THREE.PointLight(0x38bdf8, 0.6, 12);
    blueLight.position.set(-3, 3, 2);
    scene.add(blueLight);

    buildLabBench();
    buildFlask1();
    buildFlask2();
    buildCrystals();

    setupInteractions();
    updateCalculations();
    window.addEventListener('resize', onWindowResize);
    animate();
  }

  function buildLabBench() {
    const benchGeo = new THREE.BoxGeometry(12, 0.4, 7);
    const benchMat = new THREE.MeshStandardMaterial({ color: 0x1e293b, roughness: 0.35 });
    const bench = new THREE.Mesh(benchGeo, benchMat);
    bench.position.y = -0.2;
    bench.receiveShadow = true;
    scene.add(bench);

    const grid = new THREE.GridHelper(10, 20, 0x334155, 0x1e293b);
    grid.position.y = 0.01;
    scene.add(grid);
  }

  // Volumetric Flask 1 (Mother Solution S0)
  function buildFlask1() {
    flask1Group = new THREE.Group();
    flask1Group.position.set(-1.6, 0, 0);

    // Lathe profile for 100 mL Volumetric Flask
    const pts = [
      new THREE.Vector2(0.85, 0.0),
      new THREE.Vector2(0.9, 0.4),
      new THREE.Vector2(0.7, 1.1),
      new THREE.Vector2(0.25, 1.6),
      new THREE.Vector2(0.25, 2.7),
      new THREE.Vector2(0.3, 2.8),
    ];
    const glassGeo = new THREE.LatheGeometry(pts, 32);
    const glassMat = new THREE.MeshPhysicalMaterial({
      color: 0xffffff,
      transparent: true,
      opacity: 0.35,
      roughness: 0.05,
      transmission: 0.92,
      ior: 1.5,
    });
    const flask = new THREE.Mesh(glassGeo, glassMat);
    flask.castShadow = true;
    flask1Group.add(flask);

    // Etched gauge ring on neck
    const ringGeo = new THREE.TorusGeometry(0.26, 0.01, 16, 32);
    const ringMat = new THREE.MeshBasicMaterial({ color: 0xffffff });
    const ring = new THREE.Mesh(ringGeo, ringMat);
    ring.rotation.x = Math.PI / 2;
    ring.position.y = 2.1;
    flask1Group.add(ring);

    // Liquid in Flask 1
    const liquidGeo = new THREE.CylinderGeometry(0.24, 0.85, 2.0, 32);
    const liquidMat = new THREE.MeshStandardMaterial({
      color: 0x38bdf8,
      transparent: true,
      opacity: 0.2, // clear initially
      roughness: 0.1,
    });
    liquid1Mesh = new THREE.Mesh(liquidGeo, liquidMat);
    liquid1Mesh.position.y = 1.05;
    flask1Group.add(liquid1Mesh);

    // Glass stirring rod
    const rodGeo = new THREE.CylinderGeometry(0.04, 0.04, 2.8, 16);
    const rodMat = new THREE.MeshPhysicalMaterial({ color: 0xffffff, transparent: true, opacity: 0.6 });
    stirrerMesh = new THREE.Mesh(rodGeo, rodMat);
    stirrerMesh.position.set(0.05, 1.6, 0);
    stirrerMesh.rotation.z = -0.15;
    flask1Group.add(stirrerMesh);

    scene.add(flask1Group);
  }

  // Volumetric Flask 2 (Diluted Solution S1)
  function buildFlask2() {
    flask2Group = new THREE.Group();
    flask2Group.position.set(1.6, 0, 0);

    const pts = [
      new THREE.Vector2(0.85, 0.0),
      new THREE.Vector2(0.9, 0.4),
      new THREE.Vector2(0.7, 1.1),
      new THREE.Vector2(0.25, 1.6),
      new THREE.Vector2(0.25, 2.7),
      new THREE.Vector2(0.3, 2.8),
    ];
    const glassGeo = new THREE.LatheGeometry(pts, 32);
    const glassMat = new THREE.MeshPhysicalMaterial({
      color: 0xffffff,
      transparent: true,
      opacity: 0.35,
      roughness: 0.05,
      transmission: 0.92,
      ior: 1.5,
    });
    const flask = new THREE.Mesh(glassGeo, glassMat);
    flask2Group.add(flask);

    // Liquid in Flask 2 (initially empty)
    const liquidGeo = new THREE.CylinderGeometry(0.24, 0.85, 2.0, 32);
    const liquidMat = new THREE.MeshStandardMaterial({
      color: 0xbae6fd,
      transparent: true,
      opacity: 0.0, // hidden until dilution
      roughness: 0.1,
    });
    liquid2Mesh = new THREE.Mesh(liquidGeo, liquidMat);
    liquid2Mesh.position.y = 1.05;
    flask2Group.add(liquid2Mesh);

    scene.add(flask2Group);
  }

  // Solute Crystals on Watch Glass
  function buildCrystals() {
    crystalGroup = new THREE.Group();
    crystalGroup.position.set(-1.6, 0.05, 1.8);

    // Watch glass dish
    const dishGeo = new THREE.CylinderGeometry(0.65, 0.55, 0.06, 24);
    const dishMat = new THREE.MeshPhysicalMaterial({ color: 0xffffff, transparent: true, opacity: 0.45 });
    const dish = new THREE.Mesh(dishGeo, dishMat);
    crystalGroup.add(dish);

    // Cluster of vibrant blue CuSO4 crystals
    const crystalGeo = new THREE.DodecahedronGeometry(0.08);
    const crystalMat = new THREE.MeshStandardMaterial({
      color: 0x1d4ed8,
      roughness: 0.2,
      metalness: 0.1,
    });

    for (let i = 0; i < 28; i++) {
      const c = new THREE.Mesh(crystalGeo, crystalMat);
      c.position.set(
        (Math.random() - 0.5) * 0.45,
        0.05 + Math.random() * 0.12,
        (Math.random() - 0.5) * 0.45
      );
      c.rotation.set(Math.random(), Math.random(), Math.random());
      crystalGroup.add(c);
    }

    scene.add(crystalGroup);
  }

  function setupInteractions() {
    // Rotation Controls
    const dom = renderer.domElement;
    dom.addEventListener('mousedown', (e) => {
      isDragging = true;
      prevMousePos = { x: e.clientX, y: e.clientY };
    });
    window.addEventListener('mouseup', () => (isDragging = false));
    window.addEventListener('mousemove', (e) => {
      if (!isDragging) return;
      sceneRotationY += (e.clientX - prevMousePos.x) * 0.008;
      prevMousePos = { x: e.clientX, y: e.clientY };
    });

    // Mobile touch
    dom.addEventListener('touchstart', (e) => {
      if (e.touches.length === 1) {
        isDragging = true;
        prevMousePos = { x: e.touches[0].clientX, y: e.touches[0].clientY };
      }
    });
    window.addEventListener('touchend', () => (isDragging = false));
    window.addEventListener('touchmove', (e) => {
      if (!isDragging || e.touches.length !== 1) return;
      sceneRotationY += (e.touches[0].clientX - prevMousePos.x) * 0.008;
      prevMousePos = { x: e.touches[0].clientX, y: e.touches[0].clientY };
    });

    // Mass Slider
    DOM.inputMass.addEventListener('input', (e) => {
      state.mass = parseFloat(e.target.value);
      DOM.sliderMassVal.textContent = state.mass.toFixed(1) + ' g';
      updateCalculations();
      if (state.isDissolved) {
        applySolutionColor();
      }
    });

    DOM.btnDissolve.addEventListener('click', triggerDissolution);
    DOM.btnDilute.addEventListener('click', triggerDilution);
    DOM.btnConclusion.addEventListener('click', () => DOM.modal.classList.add('show'));
    DOM.modalCloseBtn.addEventListener('click', () => DOM.modal.classList.remove('show'));
    DOM.btnReset.addEventListener('click', resetExperiment);
  }

  function updateCalculations() {
    const moles = state.mass / MOLAR_MASS;
    const c0 = moles / VOL_0;
    const c1 = c0 / DILUTION_FACTOR;

    DOM.calcMass.textContent = state.mass.toFixed(2) + ' g';
    DOM.calcMoles.textContent = moles.toFixed(4) + ' mol';
    DOM.calcC0.textContent = c0.toFixed(3) + ' mol/L';
    DOM.calcC1.textContent = c1.toFixed(3) + ' mol/L';
  }

  // Action: Dissolve Solute & Stir
  function triggerDissolution() {
    if (state.isDissolved) return;
    state.isDissolved = true;
    state.step = 2;
    updateStepHUD();

    // Fade out crystal dish
    let progress = 0;
    const interval = setInterval(() => {
      progress += 0.05;
      crystalGroup.position.y = 0.05 - progress * 0.5;
      stirrerMesh.rotation.z = -0.15 + Math.sin(progress * 20) * 0.2; // stirring animation
      applySolutionColor(progress);

      if (progress >= 1.0) {
        clearInterval(interval);
        crystalGroup.visible = false;
        state.step = 3;
        updateStepHUD();
        sendEventToParent('dissolution_completed', {
          mass: state.mass,
          concentration: state.mass / (MOLAR_MASS * VOL_0),
        });
      }
    }, 30);
  }

  function applySolutionColor(factor = 1.0) {
    const c0 = (state.mass / (MOLAR_MASS * VOL_0));
    // Color intensity proportional to concentration
    const blueTone = Math.min(0.95, 0.4 + (c0 / 0.6) * 0.5);
    liquid1Mesh.material.color.setRGB(0.1, 0.55 - (c0 * 0.2), blueTone);
    liquid1Mesh.material.opacity = (0.3 + (c0 / 0.6) * 0.5) * factor;
  }

  // Action: Perform Dilution
  function triggerDilution() {
    if (!state.isDissolved || state.isDiluted) return;
    state.isDiluted = true;
    state.step = 4;
    updateStepHUD();
    DOM.dilutionRow.style.display = 'flex';

    // Animate dilution in Flask 2: lighter, more transparent blue
    const c1 = (state.mass / (MOLAR_MASS * VOL_0)) / DILUTION_FACTOR;
    liquid2Mesh.material.color.setRGB(0.5, 0.8, 0.98); // light pastel blue

    let opacity = 0;
    const interval = setInterval(() => {
      opacity += 0.04;
      liquid2Mesh.material.opacity = Math.min(0.38, opacity);
      if (opacity >= 0.38) {
        clearInterval(interval);
        setTimeout(() => DOM.modal.classList.add('show'), 600);
        sendEventToParent('dilution_completed', {
          c0: state.mass / (MOLAR_MASS * VOL_0),
          c1: c1,
          dilutionFactor: DILUTION_FACTOR,
        });
      }
    }, 40);
  }

  function updateStepHUD() {
    if (state.step === 1) {
      DOM.stepBadge.textContent = 'المرحلة 1 من 4: الذوبان';
      DOM.stepText.textContent =
        'حدد كتلة المذاب m، ثم اضغط على «إذابة وتحريك» لإذابة كبريتات النحاس داخل الحوجلة العيارية S₀.';
    } else if (state.step === 2) {
      DOM.stepBadge.textContent = 'المرحلة 2 من 4: جاري التحريك والإذابة';
      DOM.stepText.textContent =
        'تنتشر بلورات CuSO₄ في الماء المقطر ويتشكل محلول متجانس ذو لون أزرق مميز يتناسب مع التركيز C₀.';
    } else if (state.step === 3) {
      DOM.stepBadge.textContent = 'المرحلة 3 من 4: المحلول الأم S₀ جاهز';
      DOM.stepText.textContent =
        'تم تحضير المحلول الأم بنجاح! اضغط الآن على «إجراء التخفيف (Dilution F=5)» لأخذ حجم V₀ وتمديده بالماء المقطر.';
    } else if (state.step === 4) {
      DOM.stepBadge.textContent = 'المرحلة 4 من 4: انخفاض التركيز والتخفيف';
      DOM.stepText.textContent =
        'لاحظ كيف أصبح لون المحلول المخفف S₁ فاتحاً وأقل تركيزاً بمقدار 5 مرات (C₁ = C₀ / 5). انحفاظ كمية المادة n₀ = n₁!';
    }
  }

  function resetExperiment() {
    state = {
      mass: 5.0,
      isDissolved: false,
      isDiluted: false,
      step: 1,
    };
    DOM.inputMass.value = '5.0';
    DOM.sliderMassVal.textContent = '5.0 g';
    DOM.dilutionRow.style.display = 'none';
    DOM.modal.classList.remove('show');
    updateCalculations();
    updateStepHUD();

    crystalGroup.visible = true;
    crystalGroup.position.set(-1.6, 0.05, 1.8);
    liquid1Mesh.material.opacity = 0.2;
    liquid1Mesh.material.color.setHex(0x38bdf8);
    liquid2Mesh.material.opacity = 0.0;
    stirrerMesh.rotation.z = -0.15;
  }

  function sendEventToParent(action, payload) {
    const message = JSON.stringify({ source: 'meraj3i_virtual_lab', action, payload });
    if (window.parent && window.parent !== window) {
      window.parent.postMessage(message, '*');
    }
  }

  function onWindowResize() {
    const container = document.getElementById('canvas-container');
    const width = container.clientWidth || window.innerWidth;
    const height = container.clientHeight || window.innerHeight;
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
    renderer.setSize(width, height);
  }

  function animate() {
    requestAnimationFrame(animate);
    scene.rotation.y += (sceneRotationY - scene.rotation.y) * 0.1;
    renderer.render(scene, camera);
  }

  window.addEventListener('DOMContentLoaded', initThree);
})();
