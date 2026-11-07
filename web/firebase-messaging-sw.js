// Firebase Messaging Service Worker
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBw2FlmrjwtHRhS3SbzZs6sHGqtJgu9Xo4',
  appId: '1:575410287121:web:14630d4feeb4df36cdb7b0',
  messagingSenderId: '575410287121',
  projectId: 'planles-custom',
  authDomain: 'planles-custom.firebaseapp.com',
  storageBucket: 'planles-custom.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
});
