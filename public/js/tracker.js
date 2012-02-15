var tracker;

$(document).ready(function() {
  tracker = new TrackerKeeper();
  $(".story a.name").click(function() {
    tracker.loadStory(
      $(this).parents(".story").attr("data-project-id"),
      $(this).parents(".story").attr("data-story-id")
    );
    return false;
  });
  $(".story .action").click(function() {
    tracker.updateStatus(
      $(this).parents(".story").attr("data-project-id"),
      $(this).parents(".story").attr("data-story-id"),
      $(this).val()
    );
    return false;
  });
});

var TrackerKeeper = function() {
  this.loadStory = (function(projectId, storyId) {
    var description = $("div [data-story-id="+storyId+"] .description")
    if (description.size() > 0) {
      if (description.html() == "") {
        $.ajax({
          type:'GET',
          data:'storyId='+storyId+'&projectId='+projectId,
          url:'/load',
          success:function(data) {
            description.html(data).show();
          }
        });
      } else {
        description.toggle();
      }
    }
  });

  this.updateStatus = (function(projectId, storyId, action) {
    var button = $("div [data-story-id="+storyId+"] input[value="+action+"]")
    if (button.size() > 0) {
      button.attr("disabled","disabled");
      $.ajax({
        type:'POST',
        data:'storyId='+storyId+'&projectId='+projectId+'&action='+action,
        url:'/update',
        success:function(data) {
          button.parents(".actions").html(data);
          button.removeAttr("disabled");
        }
      });
    }
  });
}