/*
 * Copyright (C) 2011, 2015 Collabora Ltd.
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 *       Philip Withnall <philip.withnall@collabora.co.uk>
 */

using Gee;
using GLib;

/**
 * A view of {@link Individual}s which match a given {@link Query}.
 *
 * The search view supports ‘live’ and ‘snapshot’ search results. Live results
 * will continue to update over a long period of time as persona stores go
 * online and offline or individuals are edited so they start or stop matching
 * the {@link Query}.
 *
 * For a shell search provider, for example, snapshot results are appropriate.
 * For a search in a contacts UI, live results are more appropriate as they will
 * update over time as other edits are made in the application.
 *
 * In both cases, {@link SearchView.individuals} is guaranteed to be correct
 * after {@link SearchView.prepare} finishes.
 *
 * For live results, continue listening to the
 * {@link SearchView.individuals_changed_detailed} signal.
 *
 * @since 0.11.0
 */
public class Folks.SearchView : Object
{
  private bool _prepare_pending = false;

  private IndividualAggregator _aggregator;
  /**
   * The {@link IndividualAggregator} that this view is based upon.
   *
   * @since 0.11.0
   */
  public IndividualAggregator aggregator
    {
      get { return this._aggregator; }
    }

  private Query _query;
  /**
   * The {@link Query} that this view is based upon.
   *
   * If this {@link SearchView} has already been prepared, setting this will
   * force a re-evaluation of all {@link Individual}s in the
   * {@link IndividualAggregator} which can be an expensive operation.
   *
   * This re-evaluates the query immediately, so most clients should implement
   * de-bouncing to ensure re-evaluation only happens when (for example) the
   * user has stopped typing a new query.
   *
   * @since 0.11.0
   */
  public Query query
    {
      get { return this._query; }
      set
        {
          if (this._query == value)
            return;

          if (this._query != null)
            {
              debug ("SearchView's query replaced, forcing re-evaluation of " +
                  "all Individuals.");
            }

          this._query.notify.disconnect (this._query_notify_cb);
          this._query = value;
          this._query.notify.connect (this._query_notify_cb);

          /* Re-evaluate all Individuals (only if necessary) */
          this.refresh.begin ();
        }
    }

  private SortedSet<Individual> _individuals;
  private SortedSet<Individual> _individuals_ro;
  /**
   * A sorted set of {@link Individual}s which match the search query.
   *
   * This is the canonical set of {@link Individual}s provided by this
   * view. It is sorted by match strength, with the individual who is the best
   * match to the search query as the {@link Gee.SortedSet.first} element of
   * the set.
   *
   * Match strengths are not publicly exposed, as they are on an arbitrary
   * scale. To compare two matching individuals for match strength, check for
   * membership of one of them in the {@link Gee.SortedSet.head_set} of the
   * other.
   *
   * For clients who only wish to have a snapshot of search results, this
   * property is valid once {@link SearchView.prepare} is finished and this
   * {@link SearchView} may be unreferenced and ignored afterward.
   *
   * @since 0.11.0
   */
  public SortedSet<Individual> individuals
    {
      get { return this._individuals_ro; }
    }

  private bool _is_prepared = false;
  /**
   * Whether {@link IndividualAggregator.prepare} has successfully completed for
   * this view's aggregator.
   *
   * @since 0.11.0
   */
  public bool is_prepared
    {
      get { return this._is_prepared; }
    }

  /**
   * Whether the search view has reached a quiescent state. This will happen at
   * some point after {@link IndividualAggregator.prepare} has successfully
   * completed for its aggregator.
   *
   * It's guaranteed that this property's value will only ever change after
   * {@link SearchView.is_prepared} has changed to ``true``.
   *
   * @since 0.11.0
   */
  public bool is_quiescent
    {
      /* Just proxy the aggregator’s quiescence. If we implement anything fancy
       * and async in our matching in future, this can change. */
      get { return this.aggregator.is_quiescent; }
    }

  private void _aggregator_is_quiescent_cb ()
    {
      this.notify_property ("is-quiescent");
    }

  /**
   * Emitted when one or more {@link Individual}s are added to or removed from
   * the view.
   *
   * The sets of `added` and `removed` individuals are sorted by descending
   * match strength. Using the {@link Gee.SortedSet.lower} and
   * {@link Gee.SortedSet.higher} APIs with {@link SearchView.individuals}, the
   * `added` individuals can be inserted at the correct positions in a UI
   * representation of the search view.
   *
   * The match strengths are on the same scale as in
   * {@link SearchView.individuals}, so orderings between the two sorted sets
   * are valid. See {@link SearchView.individuals} for more information about
   * match strengths.
   *
   * @param added a set of {@link Individual}s added to the search view
   * @param removed a set of {@link Individual}s removed from the search view
   *
   * @see IndividualAggregator.individuals_changed_detailed
   * @since 0.11.0
   */
  public signal void individuals_changed_detailed (SortedSet<Individual> added,
      SortedSet<Individual> removed);

  /**
   * Create a new view of Individuals matching a given query.
   *
   * This view will be kept up-to-date as individuals change (which may change
   * their membership in the results).
   *
   * @param query query to match upon
   * @param aggregator the {@link IndividualAggregator} to match within
   *
   * @since 0.11.0
   */
  public SearchView (IndividualAggregator aggregator, Query query)
    {
      debug ("Constructing SearchView %p", this);

      this._aggregator = aggregator;
      this._aggregator.notify["is-quiescent"].connect (
          this._aggregator_is_quiescent_cb);
      this._individuals = this._create_empty_sorted_set ();
      this._individuals_ro = this._individuals.read_only_view;
      this._is_prepared = false;
      this._prepare_pending = false;
      this._query = query;
    }

  ~SearchView ()
    {
      debug ("Destroying SearchView %p", this);

      this._aggregator.notify["is-quiescent"].disconnect (
          this._aggregator_is_quiescent_cb);
    }

  /**
   * Prepare the view for use.
   *
   * This calls {@link IndividualAggregator.prepare} as necessary to start
   * aggregating all {@link Individual}s.
   *
   * This function is guaranteed to be idempotent, so multiple search views may
   * share a single aggregator; {@link SearchView.prepare} must be called on all
   * of the views.
   *
   * For any clients only interested in a snapshot of search results,
   * {@link SearchView.individuals} is valid once this async function is
   * finished.
   *
   * @throws GLib.Error if preparation failed
   *
   * @since 0.11.0
   */
  public async void prepare () throws GLib.Error
    {
      if (!this._is_prepared && !this._prepare_pending)
        {
          this._prepare_pending = true;
          this._aggregator.individuals_changed_detailed.connect (
              this._aggregator_individuals_changed_detailed_cb);
          try
            {
              yield this._aggregator.prepare ();
            }
          catch (GLib.Error e)
            {
              this._prepare_pending = false;
              this._aggregator.individuals_changed_detailed.disconnect (
                  this._aggregator_individuals_changed_detailed_cb);

              throw e;
            }

          this._is_prepared = true;
          this._prepare_pending = false;
          this.notify_property ("is-prepared");

          yield this.refresh ();
        }
    }

  /**
   * Clean up and release resources used by the search view.
   *
   * This will disconnect the aggregator cleanly from any resources it is using.
   * It is recommended to call this method before finalising the search view,
   * but calling it is not required.
   *
   * Note that this will not unprepare the underlying aggregator: call
   * {@link IndividualAggregator.unprepare} to do that. This allows multiple
   * search views to use a single aggregator and unprepare at different times.
   *
   * Concurrent calls to this function from different threads will block until
   * preparation has completed. However, concurrent calls to this function from
   * a single thread might not, i.e. the first call will block but subsequent
   * calls might return before the first one. (Though they will be safe in every
   * other respect.)
   *
   * @since 0.11.0
   * @throws GLib.Error if unpreparing the backend-specific services failed —
   * this will be a backend-specific error
   */
  public async void unprepare () throws GLib.Error
    {
      if (!this._is_prepared || this._prepare_pending)
       {
         return;
       }

      this._prepare_pending = false;
    }

  /**
   * Refresh the view’s results.
   *
   * Explicitly re-match all the view’s results to ensure matches are up to
   * date. For a normal {@link IndividualAggregator}, this is explicitly not
   * necessary, as the view will watch signal emissions from the aggregator and
   * keep itself up to date.
   *
   * However, for search-only persona stores, which do not support notification
   * of changes to personas, this method is the only way to update the set of
   * matches against the store.
   *
   * This method should be called whenever an explicit update is needed to the
   * search results, e.g. if the user requests a refresh.
   *
   * @throws GLib.Error if matching failed
   * @since 0.11.0
   */
  public async void refresh () throws GLib.Error
    {
      if (this._is_prepared)
          this._evaluate_all_aggregator_individuals ();
    }

  private void _aggregator_individuals_changed_detailed_cb (
      MultiMap<Individual?, Individual?> changes)
    {
      this._evaluate_individuals (changes, null);
    }

  private string _build_match_strength_key ()
    {
      /* FIXME: This is a pretty big hack. Ideally, we would use a custom
       * SortedSmallSet implementation, written in C and using a GPtrArray,
       * instead of TreeSet and this GObject data hackery.
       *
       * However, since we’re dealing with small result sets, this is good
       * enough for a first implementation. */
      return "folks-match-strength-%p".printf (this);
    }

  private int _compare_individual_matches (Individual a, Individual b)
    {
      /* Zero must only be returned if the individuals are equal, not in terms
       * of their match strength, but in terms of their content. */
      if (a == b)
         return 0;

      var key = this._build_match_strength_key ();

      /* If either of these are unset, they will be zero, meaning they don’t
       * match the query. Normal match strengths are positive, so that works out
       * fine. */
      var match_strength_a = a.get_data<uint> (key);
      var match_strength_b = b.get_data<uint> (key);

      if (match_strength_a != match_strength_b)
         return ((int) match_strength_b - (int) match_strength_a);

      /* Break match strength ties by display name. */
      var display_name = a.display_name.collate (b.display_name);
      if (display_name != 0)
          return display_name;

      /* Break display name ties by ID (which will be stable). */
      return a.id.collate (b.id);
    }

  private SortedSet<Individual> _create_empty_sorted_set ()
    {
      return new TreeSet<Individual> (this._compare_individual_matches);
    }

  private void _evaluate_individuals (
      MultiMap<Individual?, Individual?>? changes,
      Set<Individual?>? evaluates)
    {
      var view_added = this._create_empty_sorted_set ();
      var view_removed = this._create_empty_sorted_set ();

      /* Determine whether each evaluate should be added or removed (note that
       * pure adds from 'changes' may only be added, never removed) */
      if (evaluates != null)
        {
          foreach (var evaluate in evaluates)
            {
              if (evaluate == null)
                continue;

              if (this._check_match (evaluate))
                  view_added.add (evaluate);
              else
                  view_removed.add (evaluate);
            }
        }

      /* Determine which adds and removals make sense for the given query */
      if (changes != null)
        {
          /* Determine whether given adds should actually be added (they mostly
           * come from the Aggregator, so we need to filter out non-matches) */
          var iter = changes.map_iterator ();

          while (iter.next ())
            {
              var individual_old = iter.get_key ();
              var individual_new = iter.get_value ();

              if (individual_new != null && this._check_match (individual_new))
                {
                  /* @individual_new is being added (if @individual_old is
                   * `null`) or replacing @individual_old. */
                  view_added.add (individual_new);
                }

              if (individual_old != null)
                {
                  /* If @individual_new doesn’t match, or if @individual_old is
                   * simply being removed, ensure there’s an entry in the change
                   * set to remove @individual_old. */
                  view_removed.add (individual_old);
                }
            }
        }

      /* Perform all removals. Update the @view_removed set if we haven’t ever
       * exposed the individual in {@link SearchView.individuals}. */
      var iter = view_removed.iterator ();

      while (iter.next ())
        {
          var individual_old = iter.get ();

          if (individual_old != null &&
              !this._remove_individual (individual_old))
            {
              iter.remove ();
            }
        }

      /* Perform all additions. Update the @view_added set if we haven’t ever
       * exposed the individual in {@link SearchView.individuals}. */
      iter = view_added.iterator ();

      while (iter.next ())
        {
          var individual_new = iter.get ();

          if (individual_new != null && !this._add_individual (individual_new))
            {
              iter.remove ();
            }
        }

      /* Notify of changes. */
      if (view_added.size > 0 || view_removed.size > 0)
          this.individuals_changed_detailed (view_added, view_removed);
    }

  private inline bool _add_individual (Individual individual)
    {
      if (this._individuals.add (individual))
        {
          individual.notify.connect (this._individual_notify_cb);
          return true;
        }

      return false;
    }

  private inline bool _remove_individual (Individual individual)
    {
      if (this._individuals.remove (individual))
        {
          individual.notify.disconnect (this._individual_notify_cb);
          return true;
        }

      return false;
    }

  private void _evaluate_all_aggregator_individuals ()
    {
      var individuals = new HashSet<Individual?> ();
      individuals.add_all (this._aggregator.individuals.values);
      this._evaluate_individuals (null, individuals);
    }

  /* Returns whether the individual matches the current query. */
  private bool _check_match (Individual individual)
    {
      uint match_score = this._query.is_match (individual);

      var key = this._build_match_strength_key ();
      individual.set_data (key, match_score);

      return (match_score != 0);
    }

  /* Returns true if individual matches (regardless of whether we already knew
   * about it) */
  private bool _evaluate_match (Individual individual)
    {
      var match = this._check_match (individual);

      if (match)
        {
          this._add_individual (individual);
        }
      else
        {
          this._remove_individual (individual);
        }

      return match;
    }

  private void _individual_notify_cb (Object obj, ParamSpec ps)
    {
      var individual = obj as Individual;

      if (individual == null)
          return;

      var had_individual = this._individuals.contains (individual);
      var have_individual = this._evaluate_match (individual);

      var added = (!had_individual && have_individual);
      var removed = (had_individual && !have_individual);
      var view_added = this._create_empty_sorted_set ();
      var view_removed = this._create_empty_sorted_set ();

      if (added)
          view_added.add (individual);
      else if (removed)
          view_removed.add (individual);

      if (view_added.size > 0 || view_removed.size > 0)
          this.individuals_changed_detailed (view_added, view_removed);
    }

  private void _query_notify_cb (Object obj, ParamSpec ps)
    {
      debug ("SearchView's Query changed, forcing re-evaluation of all " +
          "Individuals");
      this.refresh.begin ();
    }
}
