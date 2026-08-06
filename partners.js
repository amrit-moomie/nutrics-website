/*
 * Kitchen Partners page behaviour: mobile nav, FAQ accordion, the multi-step
 * application form (progress bar, per-step validation, URL pre-fill for
 * leads sent here after a call), and submission via formsubmit.co — the
 * same pattern the main site's contact/launch forms already use.
 */

// ---- Mobile menu (same behaviour as the homepage) --------------------------
document.addEventListener("DOMContentLoaded", function () {
  var menuBtn = document.getElementById("mobileMenuBtn");
  var navLinks = document.getElementById("navLinks");
  if (menuBtn && navLinks) {
    menuBtn.addEventListener("click", function () {
      navLinks.classList.toggle("active");
      var icon = this.querySelector("i");
      icon.classList.toggle("fa-bars");
      icon.classList.toggle("fa-times");
    });
    navLinks.querySelectorAll("a").forEach(function (link) {
      link.addEventListener("click", function () {
        navLinks.classList.remove("active");
        var icon = menuBtn.querySelector("i");
        icon.classList.remove("fa-times");
        icon.classList.add("fa-bars");
      });
    });
  }

  // ---- FAQ accordion ---------------------------------------------------
  document.querySelectorAll(".faq-item").forEach(function (item) {
    var btn = item.querySelector(".faq-q");
    btn.addEventListener("click", function () {
      var wasOpen = item.classList.contains("is-open");
      document.querySelectorAll(".faq-item").forEach(function (other) {
        other.classList.remove("is-open");
      });
      if (!wasOpen) item.classList.add("is-open");
    });
  });

  // ---- Pre-fill from a rep's link, e.g. partners.html?business=&phone=&rep= --
  var params = new URLSearchParams(window.location.search);
  var prefillMap = {
    business: "businessName",
    phone: "phone",
    location: "location",
  };
  Object.keys(prefillMap).forEach(function (param) {
    var value = params.get(param);
    if (!value) return;
    var field = document.getElementById(prefillMap[param]);
    if (field) field.value = value;
  });
  var rep = params.get("rep");
  var repField = document.getElementById("repField");
  if (rep && repField) repField.value = rep;

  // ---- Multi-step application form --------------------------------------
  var form = document.getElementById("partnerForm");
  if (!form) return;

  var steps = Array.prototype.slice.call(form.querySelectorAll(".p-form-step"));
  var total = steps.length;
  var current = 0;

  var progressFill = document.getElementById("progressFill");
  var progressSteps = document.getElementById("progressSteps");
  var stepLabel = document.getElementById("formStepLabel");
  var backBtn = document.getElementById("formBack");
  var nextBtn = document.getElementById("formNext");
  var submitBtn = document.getElementById("formSubmit");
  var statusEl = document.getElementById("partnerFormStatus");

  // Build the progress step dots/labels once.
  steps.forEach(function (step, i) {
    var dot = document.createElement("span");
    dot.textContent = i + 1;
    if (i === 0) dot.classList.add("is-active");
    progressSteps.appendChild(dot);
  });

  function requiredFieldsValid(step) {
    var ok = true;
    var firstInvalid = null;

    step.querySelectorAll("input[required], select[required], textarea[required]").forEach(function (field) {
      if (!field.checkValidity()) {
        ok = false;
        if (!firstInvalid) firstInvalid = field;
      }
    });

    // Required checkbox pill-groups (at least one checked)
    step.querySelectorAll('.pill-group[data-required="true"]').forEach(function (group) {
      var checked = group.querySelectorAll("input:checked").length;
      if (checked === 0) {
        ok = false;
        group.classList.add("p-group-error");
        if (!firstInvalid) firstInvalid = group.querySelector("input");
      } else {
        group.classList.remove("p-group-error");
      }
    });

    if (!ok && firstInvalid) firstInvalid.focus();
    return ok;
  }

  function render() {
    steps.forEach(function (step, i) {
      step.classList.toggle("is-active", i === current);
    });

    var dots = progressSteps.querySelectorAll("span");
    dots.forEach(function (dot, i) {
      dot.classList.toggle("is-active", i === current);
    });

    progressFill.style.width = (((current + 1) / total) * 100) + "%";
    stepLabel.textContent = "Step " + (current + 1) + " of " + total;

    backBtn.classList.toggle("is-visible", current > 0);
    var isLast = current === total - 1;
    nextBtn.classList.toggle("is-hidden", isLast);
    submitBtn.classList.toggle("is-visible", isLast);
  }

  nextBtn.addEventListener("click", function () {
    if (!requiredFieldsValid(steps[current])) return;
    if (current < total - 1) {
      current++;
      render();
      form.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  });

  backBtn.addEventListener("click", function () {
    if (current > 0) {
      current--;
      render();
    }
  });

  form.addEventListener("submit", function (e) {
    e.preventDefault();
    if (!requiredFieldsValid(steps[current])) return;

    // Honeypot — a real visitor never touches this field. If it's filled,
    // pretend to succeed rather than telling a bot what tripped it.
    var honey = form.querySelector('input[name="_honey"]');
    if (honey && honey.value) {
      var wrapper = form.parentNode;
      wrapper.innerHTML =
        '<div class="success-message">' +
        '<div class="success-icon"><i class="fas fa-check-circle"></i></div>' +
        "<h3>Application received</h3>" +
        "<p>Thanks for applying to become a Trusted Culinary Partner. Our team will review your kitchen's details and follow up within a few business days.</p>" +
        "</div>";
      return;
    }

    statusEl.className = "form-status loading";
    statusEl.textContent = "Submitting your application";
    submitBtn.disabled = true;

    var formData = new FormData(form);
    formData.append("_subject", "New Nutrics kitchen partner application");

    fetch("https://formsubmit.co/ajax/amritpal750@gmail.com", {
      method: "POST",
      body: formData,
      headers: { Accept: "application/json" },
    })
      .then(function (response) {
        if (!response.ok) throw new Error("Network response was not ok");
        return response.json();
      })
      .then(function () {
        var wrapper = form.parentNode;
        wrapper.innerHTML =
          '<div class="success-message">' +
          '<div class="success-icon"><i class="fas fa-check-circle"></i></div>' +
          "<h3>Application received</h3>" +
          "<p>Thanks for applying to become a Trusted Culinary Partner. Our team will review your kitchen's details and follow up within a few business days.</p>" +
          "</div>";
      })
      .catch(function (error) {
        statusEl.className = "form-status error";
        statusEl.textContent = "There was a problem submitting your application. Please try again.";
        console.error("Partner form submission error:", error);
        submitBtn.disabled = false;
      });
  });

  render();

  // ---- Google Places autofill --------------------------------------------
  //
  // Lazy-loaded on purpose: the Maps JS bundle only loads the first time
  // someone focuses the business-search box, or immediately if the page was
  // opened with a ?placeId= link (a rep's pre-filled invite). A visitor who
  // never touches Step 1's search box never costs a single Places request —
  // that's the main defence against a scraper or bot running up API spend
  // just by loading the page. The rest of the defence (referrer + API
  // restrictions, a daily quota cap, a billing alert) lives in the Google
  // Cloud Console, not in this file — see the comment on the script include.
  var placesReady = false;
  var placesLoading = false;
  var placesQueue = [];

  function loadGooglePlaces(callback) {
    if (placesReady) return callback();
    placesQueue.push(callback);
    if (placesLoading) return;
    placesLoading = true;

    window.__nutricsPlacesReady = function () {
      placesReady = true;
      placesQueue.splice(0).forEach(function (fn) {
        fn();
      });
    };

    var script = document.createElement("script");
    script.src =
      "https://maps.googleapis.com/maps/api/js?key=" +
      window.NUTRICS_MAPS_API_KEY +
      "&libraries=places&loading=async&callback=__nutricsPlacesReady";
    script.async = true;
    document.head.appendChild(script);
  }

  // Field names here match the new Places API's Place object (camelCase,
  // fetched via place.fetchFields()) — not the legacy PlacesService shape.
  var PLACE_FIELDS = [
    "displayName",
    "formattedAddress",
    "nationalPhoneNumber",
    "websiteURI",
    "addressComponents",
    "id",
  ];

  function fillFromPlace(place) {
    if (!place) return;

    var nameField = document.getElementById("businessName");
    if (nameField && place.displayName) nameField.value = place.displayName;

    var phoneField = document.getElementById("phone");
    if (phoneField && place.nationalPhoneNumber) {
      phoneField.value = place.nationalPhoneNumber;
    }

    var websiteField = document.getElementById("website");
    if (websiteField && place.websiteURI) websiteField.value = place.websiteURI;

    var locationField = document.getElementById("location");
    if (locationField && place.addressComponents) {
      var parts = {};
      place.addressComponents.forEach(function (c) {
        if (c.types.indexOf("locality") > -1) parts.city = c.longText;
        if (c.types.indexOf("sublocality") > -1 && !parts.city) parts.city = c.longText;
        if (c.types.indexOf("administrative_area_level_1") > -1) parts.region = c.shortText;
      });
      var summary = [parts.city, parts.region].filter(Boolean).join(", ");
      locationField.value = summary || place.formattedAddress || "";
    } else if (locationField && place.formattedAddress) {
      locationField.value = place.formattedAddress;
    }

    var placeIdField = document.getElementById("placeIdField");
    if (placeIdField && place.id) placeIdField.value = place.id;
  }

  function showPlaceSearchError(message) {
    var hint = document.getElementById("placeSearchHint");
    if (hint) {
      hint.textContent = message;
      hint.classList.add("is-error");
    }
  }

  var placeSearchWrap = document.getElementById("placeSearchWrap");
  var placeSearchFallback = document.getElementById("placeSearchFallback");
  var autocompleteBound = false;

  function initAutocomplete() {
    if (autocompleteBound || !placeSearchWrap || !window.google) return;
    if (!google.maps.places || !google.maps.places.PlaceAutocompleteElement) {
      showPlaceSearchError(
        "Search is temporarily unavailable — just fill in the fields below manually."
      );
      return;
    }
    autocompleteBound = true;

    var el = new google.maps.places.PlaceAutocompleteElement({
      includedRegionCodes: ["ca"],
      // Roughly the GTA — Hamilton to Oshawa, Lake Ontario to Newmarket.
      // Without this, predictions for a short query aren't weighted toward
      // Toronto at all and irrelevant results from other provinces can
      // outrank the actual local business you're typing.
      locationBias: { west: -80.2, south: 43.3, east: -78.9, north: 44.2 },
    });
    el.id = "placeSearch";
    placeSearchWrap.appendChild(el);
    placeSearchWrap.classList.add("is-live");

    el.addEventListener("gmp-select", function (event) {
      var place = event.placePrediction.toPlace();
      place
        .fetchFields({ fields: PLACE_FIELDS })
        .then(function () {
          fillFromPlace(place);
        })
        .catch(function (err) {
          console.error("Place details lookup failed:", err);
        });
    });
  }

  if (placeSearchFallback) {
    placeSearchFallback.addEventListener(
      "focus",
      function () {
        loadGooglePlaces(initAutocomplete);
      },
      { once: true }
    );
  }

  // A rep-sent link: partners.html?placeId=ChIJ... pre-fills Step 1 from the
  // Places record so the applicant only has to check it and hit Next.
  var placeId = params.get("placeId");
  if (placeId) {
    loadGooglePlaces(function () {
      if (!google.maps.places || !google.maps.places.Place) return;
      var place = new google.maps.places.Place({ id: placeId });
      place
        .fetchFields({ fields: PLACE_FIELDS })
        .then(function () {
          fillFromPlace(place);
        })
        .catch(function (err) {
          console.error("Place lookup from URL failed:", err);
        });
    });
  }

});
