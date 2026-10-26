(() => {
  const byAttribute = (name) => document.querySelector(
    `[name="user.attributes.${name}"], [name="attributes.${name}"], [name="${name}"]`
  );

  const fieldGroup = (el) => el?.closest(
    '.pf-v5-c-form__group, .kc-form-group, .form-group, .pf-c-form__group'
  ) || el?.parentElement;

  const syncWorkLocation = () => {
    const location = byAttribute('work_location');
    const other = byAttribute('work_location_other');
    if (!location || !other) return;

    if (!location.value) {
      const defaultOption = [...location.options].find((option) => option.value === 'Wisma Raharja');
      if (defaultOption) location.value = 'Wisma Raharja';
    }

    const otherGroup = fieldGroup(other);
    const isOther = location.value === 'Lainnya';

    if (otherGroup) otherGroup.classList.toggle('aru-hidden', !isOther);
    other.required = isOther;
    other.setAttribute('aria-required', isOther ? 'true' : 'false');
  };

  const init = () => {
    syncWorkLocation();
    const location = byAttribute('work_location');
    if (location) location.addEventListener('change', syncWorkLocation);

    const form = document.querySelector('form');
    if (form) {
      form.addEventListener('submit', (event) => {
        const location = byAttribute('work_location');
        const other = byAttribute('work_location_other');
        if (location?.value === 'Lainnya' && other && !other.value.trim()) {
          event.preventDefault();
          other.focus();
          other.setCustomValidity('Isi lokasi kerja lainnya.');
          other.reportValidity();
        } else if (other) {
          other.setCustomValidity('');
        }
      });
    }
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
