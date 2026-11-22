/**
 * محاكاة ثلاثية الأبعاد تفاعلية: قانون انحفاظ الكتلة (Conservation de la masse)
 * منصة مراجعي التعليمية MERAJ3I - 3D Virtual Lab
 */

(function () {
  'use strict';

  // State
  let state = {
    mass: 152.40,
    tareOffset: 0.0,
    hasReacted: false,
    isReacting: false,
    stopperOpen: false,
    gasEscaped: false,
    step: 1,
  };

  const DOM = {
    scaleValue: document.getElementById('scale-value'),
    stepBadge: document.getElementById('step-badge'),
    stepText: document.getElementById('step-text'),
    btnReact: document.getElementById('btn-react'),
    btnStopper: document.getElementById('btn-stopper'),
    btnTare: document.getElementById('btn-tare'),
    btnConclusion: document.getElementById('btn-conclusion'),
    btnReset: document.getElementById('btn-reset'),
    modal: document.getElementById('observation-modal'),
    modalCloseBtn: document.getElementById('modal-close-btn'),
  };

  // Three.js Core Objects
  let scene, camera, renderer;
  let flaskGroup, stopperMesh, innerTubeGroup, liquidMesh, bubbles = [];
  let gasParticles = [];
  let isDragging = false, prevMousePos = { x: 0, y: 0 };
  let sceneRotationY = 0;

  function initThree() {
    const container = document.getElementById('canvas-container');
    const width = container.clientWidth || window.innerWidth;
    const height = container.clientHeight || window.innerHeight;

    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0c1424);
    scene.fog = new THREE.FogExp2(0x0c1424, 0.04);

    camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 100);
    camera.position.set(0, 3.2, 7.5);
    camera.lookAt(0, 1.2, 0);

    renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    container.appendChild(renderer.domElement);

    // Lights
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.65);
    scene.add(ambientLight);

    const dirLight = new THREE.DirectionalLight(0xffffff, 0.85);
    dirLight.position.set(5, 10, 7);
    dirLight.castShadow = true;
    dirLight.shadow.mapSize.width = 1024;
    dirLight.shadow.mapSize.height = 1024;
    scene.add(dirLight);

    const blueRimLight = new THREE.PointLight(0x38bdf8, 0.6, 12);
    blueRimLight.position.set(-4, 3, -2);
    scene.add(blueRimLight);

    buildLabEnvironment();
    buildScale();
    buildFlaskAndReactants();

    setupInteractions();
    window.addEventListener('resize', onWindowResize);
    animate();
  }

  // 1. Lab Environment
  function buildLabEnvironment() {
    // Table Top
    const tableGeo = new THREE.BoxGeometry(10, 0.4, 6);
    const tableMat = new THREE.MeshStandardMaterial({
      color: 0x1e293b,
      roughness: 0.4,
      metalness: 0.1,
    });
    const table = new THREE.Mesh(tableGeo, tableMat);
    table.position.y = -0.2;
    table.receiveShadow = true;
    scene.add(table);

    // Grid accent on bench
    const grid = new THREE.GridHelper(8, 16, 0x334155, 0x1e293b);
    grid.position.y = 0.01;
    scene.add(grid);
  }

  // 2. Precision Scale
  function buildScale() {
    const scaleGroup = new THREE.Group();

    // Base
    const baseGeo = new THREE.CylinderGeometry(1.6, 1.7, 0.35, 32);
    const baseMat = new THREE.MeshStandardMaterial({
      color: 0x0f172a,
      metalness: 0.6,
      roughness: 0.3,
    });
    const base = new THREE.Mesh(baseGeo, baseMat);
    base.position.y = 0.18;
    base.castShadow = true;
    base.receiveShadow = true;
    scaleGroup.add(base);

    // Stainless steel plate pan
    const panGeo = new THREE.CylinderGeometry(1.4, 1.4, 0.08, 32);
    const panMat = new THREE.MeshStandardMaterial({
      color: 0xe2e8f0,
      metalness: 0.9,
      roughness: 0.15,
    });
    const pan = new THREE.Mesh(panGeo, panMat);
    pan.position.y = 0.38;
    pan.castShadow = true;
    scaleGroup.add(pan);

    // Mini LED display box on front
    const ledGeo = new THREE.BoxGeometry(0.8, 0.18, 0.1);
    const ledMat = new THREE.MeshBasicMaterial({ color: 0x064e3b });
    const led = new THREE.Mesh(ledGeo, ledMat);
    led.position.set(0, 0.22, 1.55);
    scaleGroup.add(led);

    scene.add(scaleGroup);
  }

  // 3. Flask, Reactants & Stopper
  function buildFlaskAndReactants() {
    flaskGroup = new THREE.Group();
    flaskGroup.position.set(0, 0.42, 0);

    // Glass Erlenmeyer Flask Body
    const points = [];
    points.push(new THREE.Vector2(0.95, 0.0));
    points.push(new THREE.Vector2(0.95, 0.2));
    points.push(new THREE.Vector2(0.38, 1.5));
    points.push(new THREE.Vector2(0.38, 2.1));
    points.push(new THREE.Vector2(0.44, 2.2));
    const glassGeo = new THREE.LatheGeometry(points, 32);
    const glassMat = new THREE.MeshPhysicalMaterial({
      color: 0xffffff,
      transparent: true,
      opacity: 0.32,
      roughness: 0.05,
      metalness: 0.0,
      transmission: 0.9,
      ior: 1.5,
      reflectivity: 0.8,
    });
    const flask = new THREE.Mesh(glassGeo, glassMat);
    flask.castShadow = true;
    flaskGroup.add(flask);

    // Liquid inside Flask (Vinegar CH3COOH)
    const liquidGeo = new THREE.CylinderGeometry(0.82, 0.92, 0.65, 32);
    const liquidMat = new THREE.MeshStandardMaterial({
      color: 0xfef08a,
      transparent: true,
      opacity: 0.72,
      roughness: 0.15,
    });
    liquidMesh = new THREE.Mesh(liquidGeo, liquidMat);
    liquidMesh.position.y = 0.33;
    flaskGroup.add(liquidMesh);

    // Internal Tube with NaHCO3 powder inside
    innerTubeGroup = new THREE.Group();
    innerTubeGroup.position.set(0.2, 0.5, 0);
    innerTubeGroup.rotation.z = -0.4; // tilted standing inside flask

    const tubeGeo = new THREE.CylinderGeometry(0.12, 0.12, 0.8, 16);
    const tubeMat = new THREE.MeshPhysicalMaterial({
      color: 0xffffff,
      transparent: true,
      opacity: 0.5,
      transmission: 0.8,
    });
    const tube = new THREE.Mesh(tubeGeo, tubeMat);
    innerTubeGroup.add(tube);

    // Powder reactant inside test tube
    const powderGeo = new THREE.CylinderGeometry(0.1, 0.1, 0.45, 16);
    const powderMat = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.9 });
    const powder = new THREE.Mesh(powderGeo, powderMat);
    powder.position.y = -0.15;
    innerTubeGroup.add(powder);

    flaskGroup.add(innerTubeGroup);

    // Rubber Stopper on Neck
    const stopperGeo = new THREE.CylinderGeometry(0.36, 0.44, 0.35, 24);
    const stopperMat = new THREE.MeshStandardMaterial({
      color: 0x991b1b,
      roughness: 0.8,
    });
    stopperMesh = new THREE.Mesh(stopperGeo, stopperMat);
    stopperMesh.position.y = 2.15;
    stopperMesh.castShadow = true;
    flaskGroup.add(stopperMesh);

    // Bubble Particle System
    const bubbleGeo = new THREE.SphereGeometry(0.03, 8, 8);
    const bubbleMat = new THREE.MeshStandardMaterial({
      color: 0xffffff,
      transparent: true,
      opacity: 0.75,
      roughness: 0.1,
    });
    for (let i = 0; i < 45; i++) {
      const b = new THREE.Mesh(bubbleGeo, bubbleMat);
      b.position.set(
        (Math.random() - 0.5) * 1.1,
        0.05 + Math.random() * 0.5,
        (Math.random() - 0.5) * 1.1
      );
      b.visible = false;
      b.userData = { speed: 0.015 + Math.random() * 0.02, initialY: b.position.y };
      flaskGroup.add(b);
      bubbles.push(b);
    }

    // Escaping Gas Vapor Particles (for when stopper opens)
    const gasGeo = new THREE.SphereGeometry(0.06, 8, 8);
    const gasMat = new THREE.MeshBasicMaterial({
      color: 0xdcfce7,
      transparent: true,
      opacity: 0.35,
    });
    for (let i = 0; i < 30; i++) {
      const g = new THREE.Mesh(gasGeo, gasMat);
      g.position.set(0, 2.3, 0);
      g.visible = false;
      g.userData = {
        vx: (Math.random() - 0.5) * 0.02,
        vy: 0.02 + Math.random() * 0.03,
        vz: (Math.random() - 0.5) * 0.02,
        life: 0,
      };
      scene.add(g);
      gasParticles.push(g);
    }

    scene.add(flaskGroup);
  }

  // 4. Interaction Controls
  function setupInteractions() {
    // Mouse Drag to rotate scene view
    const dom = renderer.domElement;
    dom.addEventListener('mousedown', (e) => {
      isDragging = true;
      prevMousePos = { x: e.clientX, y: e.clientY };
    });
    window.addEventListener('mouseup', () => (isDragging = false));
    window.addEventListener('mousemove', (e) => {
      if (!isDragging) return;
      const dx = e.clientX - prevMousePos.x;
      sceneRotationY += dx * 0.008;
      prevMousePos = { x: e.clientX, y: e.clientY };
    });

    // Touch support for mobile devices
    dom.addEventListener('touchstart', (e) => {
      if (e.touches.length === 1) {
        isDragging = true;
        prevMousePos = { x: e.touches[0].clientX, y: e.touches[0].clientY };
      }
    });
    window.addEventListener('touchend', () => (isDragging = false));
    window.addEventListener('touchmove', (e) => {
      if (!isDragging || e.touches.length !== 1) return;
      const dx = e.touches[0].clientX - prevMousePos.x;
      sceneRotationY += dx * 0.008;
      prevMousePos = { x: e.touches[0].clientX, y: e.touches[0].clientY };
    });

    // Buttons
    DOM.btnReact.addEventListener('click', triggerReaction);
    DOM.btnStopper.addEventListener('click', toggleStopper);
    DOM.btnTare.addEventListener('click', tareScale);
    DOM.btnConclusion.addEventListener('click', () => DOM.modal.classList.add('show'));
    DOM.modalCloseBtn.addEventListener('click', () => DOM.modal.classList.remove('show'));
    DOM.btnReset.addEventListener('click', resetExperiment);
  }

  // Action: Trigger Chemical Reaction
  function triggerReaction() {
    if (state.hasReacted || state.isReacting) return;
    state.isReacting = true;
    state.step = 2;
    updateStepHUD();

    // Animate inner tube falling / mixing into vinegar
    let progress = 0;
    const interval = setInterval(() => {
      progress += 0.04;
      innerTubeGroup.rotation.z = -0.4 - progress * 1.1; // flips down
      innerTubeGroup.position.y = 0.5 - progress * 0.35;
      if (progress >= 1.0) {
        clearInterval(interval);
        startEffervescence();
      }
    }, 20);
  }

  function startEffervescence() {
    // Activate bubbles
    bubbles.forEach((b) => (b.visible = true));

    // Liquid changes color slightly to milky white effervescent
    liquidMesh.material.color.setHex(0xe0f2fe);
    liquidMesh.material.opacity = 0.88;

    setTimeout(() => {
      state.isReacting = false;
      state.hasReacted = true;
      state.step = 3;
      updateStepHUD();
      sendEventToParent('reaction_completed', { mass: state.mass });
    }, 4500);
  }

  // Action: Toggle Stopper
  function toggleStopper() {
    if (!state.stopperOpen) {
      // Open Stopper
      state.stopperOpen = true;
      DOM.btnStopper.innerHTML = '<span>🍾 غلق السدادة</span>';

      // Animate Stopper rising
      let y = 2.15;
      const interval = setInterval(() => {
        y += 0.04;
        stopperMesh.position.y = y;
        stopperMesh.position.x += 0.02;
        if (y >= 3.0) {
          clearInterval(interval);
        }
      }, 20);

      // If reacted, gas escapes and mass drops from 152.40g to 150.20g!
      if (state.hasReacted && !state.gasEscaped) {
        escapeGas();
      }
    } else {
      // Close Stopper
      state.stopperOpen = false;
      DOM.btnStopper.innerHTML = '<span>🍾 فتح السدادة</span>';
      stopperMesh.position.set(0, 2.15, 0);
    }
  }

  // Action: Escape Gas & Animate Mass Drop
  function escapeGas() {
    state.gasEscaped = true;
    gasParticles.forEach((g) => (g.visible = true));

    // Gradually decrease mass
    const targetMass = 150.20;
    const step = 0.05;
    const interval = setInterval(() => {
      if (state.mass > targetMass) {
        state.mass = Math.max(targetMass, state.mass - step);
        updateScaleHUD();
      } else {
        clearInterval(interval);
        state.step = 4;
        updateStepHUD();
        setTimeout(() => DOM.modal.classList.add('show'), 600);
        sendEventToParent('gas_escaped', {
          initialMass: 152.40,
          finalMass: 150.20,
          gasMass: 2.20,
        });
      }
    }, 50);
  }

  // Action: Tare Scale
  function tareScale() {
    state.tareOffset = state.tareOffset === 0 ? state.mass : 0;
    updateScaleHUD();
  }

  function updateScaleHUD() {
    const displayed = (state.mass - state.tareOffset).toFixed(2);
    DOM.scaleValue.textContent = displayed;
  }

  function updateStepHUD() {
    if (state.step === 1) {
      DOM.stepBadge.textContent = 'المرحلة 1 من 4';
      DOM.stepText.textContent =
        'لاحظ الكتلة الابتدائية m₁ للمتفاعلات (حمض الخل + بيكربونات الصوديوم) داخل الحوجلة المغلقة بإحكام.';
    } else if (state.step === 2) {
      DOM.stepBadge.textContent = 'المرحلة 2 من 4: فوران وتفاعل كيميائي';
      DOM.stepText.textContent =
        'يمتزج حمض الخل مع بيكربونات الصوديوم مما يسبب فوراناً شديداً وتشكل غاز CO₂. لاحظ أن الميزان يظل ثابتاً عند 152.40 g لأن النظام مغلق!';
    } else if (state.step === 3) {
      DOM.stepBadge.textContent = 'المرحلة 3 من 4: انتهاء التفاعل في وسط مغلق';
      DOM.stepText.textContent =
        'm₁ = m₂ = 152.40 g. الكتلة محفوظة بدقة تامة! اضغط الآن على «فتح السدادة» لرؤية ما يحدث عند السماح للغاز بمغادرة النظام.';
    } else if (state.step === 4) {
      DOM.stepBadge.textContent = 'المرحلة 4 من 4: انطلاق الغاز وانخفاض الكتلة';
      DOM.stepText.textContent =
        'غادر غاز CO₂ الحوجلة فانخفضت الكتلة إلى 150.20 g. كتلة الغاز المنطلق: Δm = 152.40 - 150.20 = 2.20 g!';
    }
  }

  function resetExperiment() {
    state = {
      mass: 152.40,
      tareOffset: 0.0,
      hasReacted: false,
      isReacting: false,
      stopperOpen: false,
      gasEscaped: false,
      step: 1,
    };
    updateScaleHUD();
    updateStepHUD();
    DOM.btnStopper.innerHTML = '<span>🍾 فتح السدادة</span>';
    DOM.modal.classList.remove('show');

    // Reset 3D models
    innerTubeGroup.position.set(0.2, 0.5, 0);
    innerTubeGroup.rotation.z = -0.4;
    stopperMesh.position.set(0, 2.15, 0);
    liquidMesh.material.color.setHex(0xfef08a);
    liquidMesh.material.opacity = 0.72;
    bubbles.forEach((b) => (b.visible = false));
    gasParticles.forEach((g) => (g.visible = false));
  }

  // Communication with Flutter App
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

  // Render Loop
  function animate() {
    requestAnimationFrame(animate);

    // Smooth scene rotation
    scene.rotation.y += (sceneRotationY - scene.rotation.y) * 0.1;

    // Bubbles rising animation
    if (state.isReacting) {
      bubbles.forEach((b) => {
        b.position.y += b.userData.speed;
        if (b.position.y > 0.65) {
          b.position.y = 0.1;
          b.position.x = (Math.random() - 0.5) * 1.1;
          b.position.z = (Math.random() - 0.5) * 1.1;
        }
      });
    }

    // Gas vapor rising when stopper open
    if (state.gasEscaped) {
      gasParticles.forEach((g) => {
        g.position.x += g.userData.vx;
        g.position.y += g.userData.vy;
        g.position.z += g.userData.vz;
        g.userData.life += 0.01;
        if (g.position.y > 4.5 || g.userData.life > 1.5) {
          g.position.set(0, 2.3, 0);
          g.userData.life = 0;
        }
      });
    }

    renderer.render(scene, camera);
  }

  window.addEventListener('DOMContentLoaded', initThree);
})();
