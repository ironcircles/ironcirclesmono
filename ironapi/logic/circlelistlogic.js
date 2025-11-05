/***************************************************************************
 * 
 * Author: JC
 * 
 * Purpose: Encapsulates logic for dealing with CircleImages.   
 * 
 * TODO: Replace GridFSBucket logic with /util/gridfsutil deleteblob
 * 
 *  
 ***************************************************************************/
const CircleList = require('../models/circlelist');
const CircleListTask = require('../models/circlelisttask');
const ReminderTracker = require('../models/remindertracker');
const mongoose = require('mongoose');
const logUtil = require('../util/logutil');
const ObjectID = require('mongodb').ObjectID;
const mongodb = require('mongodb');
const circle = require('../models/circle');
const e = require('express');


module.exports.deleteCircleLists = async function (circle) {

  try {

    CircleList.deleteMany({ "circle": circle._id });

  } catch (err) {
    let msg = await logUtil.logError(err, true);
  }

}

module.exports.updateList = async function (user, existingTasks, newTasks) {
  try {
    console.log('UPDATELIST:removeTasksBeforeSaving started ' + new Date(Date.now()));
    var updatedList = await removeTasksBeforeSaving(existingTasks, newTasks);
    console.log('UPDATELIST:removeTasksBeforeSaving complete ' + new Date(Date.now()));
    updatedList = await addTasksBeforeSaving(user, updatedList, newTasks);
    console.log('UPDATELIST:addTasksBeforeSaving complete ' + new Date(Date.now()));

    return updatedList;

  } catch (err) {
    let msg = await logUtil.logError(err, true);
    throw new Error(msg);
  }
}

async function removeTasksBeforeSaving(existingTasks, newTasks) {
  try {

    //determine if anything has been removed
    for (i = 0; i < existingTasks.length; i++) {

      let existingTask = existingTasks[i];

      let found = false;


      for (j = 0; j < newTasks.length; j++) {

        let task = newTasks[j];

        //don't check new ones
        if (task._id == null)
          continue;

        if (task._id == existingTask._id) {
          found = true;
          break;
        }
      }

      if (!found) {
        existingTask.seed = null;
      }

      //console.log('UPDATELIST:removeTasksBeforeSaving first outerloop ' + new Date(Date.now()));

    }

    let results = [];
    for (let i = 0; i < existingTasks.length; i++) {
      if (existingTasks[i].seed != null)

        results.push(existingTasks[i]);
      else {
        //console.log('UPDATELIST:deleteOne started ' + new Date(Date.now()));
        await CircleListTask.deleteOne({ _id: existingTasks[i]._id });
        //console.log('UPDATELIST:deleteOne completed ' + new Date(Date.now()));
      }

      //console.log('UPDATELIST:removeTasksBeforeSaving second outerloop ' + new Date(Date.now()));
    }

    return results;

  } catch (err) {
    let msg = await logUtil.logError(err, true);
    throw new Error(msg);
  }
}

/*async function removeTasksBeforeSaving (existingTasks, newTasks){
  try {
    //determine if anything has been removed
    for (i = 0; i < existingTasks.length; i++) {

      var existingTask = existingTasks[i];

      var found = false;


      for (j = 0; j < newTasks.length; j++) {

        var task = newTasks[j];

        //don't check new ones
        if (task._id == null)
          continue;

        //console.log(task._id + " == " + existingTask._id);

        if (task._id == existingTask._id) {
          found = true;
          break;
        }
      }

      if (!found) {
        await existingTasks.$pop({ _id: existingTask._id });
      }
    }

    return existingTasks;

  } catch (err) {
    console.error(err);
  }
}*/

async function addTasksBeforeSaving(user, existingTasks, newTasks) {
  try {

    for (i = 0; i < newTasks.length; i++) {

      var task = newTasks[i];

      //find the object in the list
      var existingTask = null;

      for (j = 0; j < existingTasks.length; j++) {
        if (existingTasks[j]._id == task._id) {
          existingTask = existingTasks[j];
          break;
        }
      }

      if (existingTask != null) {

        var changed = false;

        //update only what's changed
        /*if (existingTask.name != task.name) {
          changed = true;
          existingTask.name = task.name;
        }*/  //won't know if the name has changed because it's encrypted

        if (existingTask.order != task.order) {
          changed = true;
          existingTask.order = task.order;
        }

        if (existingTask.due != task.due) {
          changed = true;
          existingTask.due = task.due;

          //console.log('UPDATELIST:deleteMany started ' + new Date(Date.now()));
          await ReminderTracker.deleteMany({ 'circleListTask': existingTask._id, 'user': existingTask.assignee });
          //console.log('UPDATELIST:deleteMany completed ' + new Date(Date.now()));
        }

        if (existingTask.complete != task.complete) {
          changed = true;
          existingTask.complete = task.complete;

          if (task.complete) {
            existingTask.completed = Date.now();
            existingTask.completedBy = user;
          }
          else {
            existingTask.completed = null;
            existingTask.completedBy = null;
          }
        }


        if (task.assignee != null) {

          if (existingTask.assignee != task.assignee._id) {
            changed = true;
            existingTask.assignee = task.assignee._id;
          }

        } else if (existingTask.assignee != null) {
          changed = true;
          existingTask.assignee = null;
        }


        if (changed) {
          //console.log('UPDATELIST:existingTask.save started ' + new Date(Date.now()));
          await existingTask.save();
          //console.log('UPDATELIST:existingTask.save complete ' + new Date(Date.now()));
        }


      } else {
        //not found?  Add it. 
        var circlelisttask = new CircleListTask({ name: task.name, seed: task.seed, due: task.due, assignee: task.assignee, order: task.order });

        if (task.complete == true) {
          circlelisttask.complete = task.complete;
          circlelisttask.completed = task.completed;
          circlelisttask.completedBy = task.completedBy;
        }

        //console.log('UPDATELIST:circlelisttask.save started ' + new Date(Date.now()));
        await circlelisttask.save();
        //console.log('UPDATELIST:circlelisttask.save complete ' + new Date(Date.now()));
        existingTasks.push(circlelisttask);
        //console.log('UPDATELIST:push complete ' + new Date(Date.now()));
      }

      //console.log('UPDATELIST:addTasksBeforeSaving outerloop ' + new Date(Date.now()));

    }

    return existingTasks;

  } catch (err) {
    let msg = await logUtil.logError(err, true);
    throw new Error(msg);
  }
}

module.exports.isListComplete = async function (existingTasks) {
  try {
    var incomplete = false;

    for (i = 0; i < existingTasks.length; i++) {
      var existingTask = existingTasks[i];

      if (!existingTask.complete) incomplete = true;  //this has nothing to do with removal.  Just hijacking a for loop

    }

    return !incomplete;


  } catch (err) {
    let msg = await logUtil.logError(err, true);
    throw new Error(msg);
  }
}

module.exports.deleteCircleList = async function (circleListID) {

  try {

    var circlelist = await CircleList.findById(circleListID);

    for (i = 0; i < circlelist.tasks.length; i++) {

      await CircleListTask.deleteOne({ _id: circlelist.tasks[i] });

    }

    await CircleList.deleteOne({ _id: circleListID });

    return true;

  } catch (err) {
    let msg = await logUtil.logError(err, true);
    return false;
  }



}

