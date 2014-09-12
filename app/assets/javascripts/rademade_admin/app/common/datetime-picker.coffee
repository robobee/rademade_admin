initDatetimePicker = () ->
  $('[data-date-time-picker]').each () ->
    $datetimePicker = $(this)
    $hiddenInput = $datetimePicker.siblings('input')

    $datetimePicker.datetimepicker
      defaultDate : new Date($hiddenInput.val())

    $datetimePicker.on 'dp.change', (e) ->
      $hiddenInput.val e.date.format()

$ ->
  $(document).on 'ready page:load init-plugins', initDatetimePicker